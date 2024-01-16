# Based on https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/sgx/samples/default.nix

{ pkgs ? import (builtins.fetchTarball {
    name = "nixpkgs-unstable-2024-01-12";
    url = "https://github.com/nixos/nixpkgs/archive/e947a837d74b3c43ac11daa0bce13173b8e6de1d.tar.gz";
    sha256 = "sha256:0j9sm4vad69zh7gwn8887lfprbl2146afm614mk17p66p3m8vjiq";
  }) {},
  sgxMode ? "SIM",
  sample ? "SampleEnclave"
}:
with pkgs;

let
  isSimulation = sgxMode == "SIM";
  buildSample = name: stdenv.mkDerivation {
    pname = name;
    version = sgxMode;

    src = sgx-sdk.out;
    sourceRoot = "${sgx-sdk.name}/share/SampleCode/${name}";

    nativeBuildInputs = [
      makeWrapper
      openssl
      which
    ];

    buildInputs = [
      sgx-sdk
    ];

    # The samples don't have proper support for parallel building
    # causing them to fail randomly.
    enableParallelBuilding = false;

    buildFlags = [
      "SGX_MODE=${sgxMode}"
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,lib}
      install -m 755 app $out/bin
      install *.so $out/lib
      ${sgx-sdk}/bin/sgx_sign dump -enclave $out/lib/*.signed.so -dumpfile $out/enclave_metadata.txt

      wrapProgram "$out/bin/app" \
        --chdir "$out/lib" \
        ${lib.optionalString (false)
        ''--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ sgx-psw ]}"''}

      runHook postInstall
    '';

    # Breaks the signature of the enclaves
    dontFixup = true;

    # We don't have access to real SGX hardware during the build
    doInstallCheck = isSimulation;
    installCheckPhase = ''
      runHook preInstallCheck

      pushd /
      echo a | $out/bin/app
      popd

      runHook preInstallCheck
    '';
  };
in
({
  Cxx11SGXDemo = buildSample "Cxx11SGXDemo";
  Cxx14SGXDemo = buildSample "Cxx14SGXDemo";
  Cxx17SGXDemo = buildSample "Cxx17SGXDemo";
  LocalAttestation = (buildSample "LocalAttestation").overrideAttrs (old: {
    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,lib}
      install -m 755 bin/app* $out/bin
      install bin/*.so $out/lib

      for bin in $out/bin/*; do
        wrapProgram $bin \
          --chdir "$out/lib" \
          ${lib.optionalString (!isSimulation)
          ''--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ sgx-psw ]}"''}
      done

      runHook postInstall
    '';
  });
  PowerTransition = buildSample "PowerTransition";
  ProtobufSGXDemo = buildSample "ProtobufSGXDemo";
  RemoteAttestation = (buildSample "RemoteAttestation").overrideAttrs (old: {
    # Makefile sets rpath to point to $TMPDIR
    preFixup = ''
      patchelf --remove-rpath $out/bin/app
    '';

    postInstall = ''
      install sample_libcrypto/*.so $out/lib
    '';
  });
  SampleEnclave = buildSample "SampleEnclave";
  SampleEnclaveGMIPP = buildSample "SampleEnclaveGMIPP";
  SampleMbedCrypto = buildSample "SampleMbedCrypto";
  SealUnseal = (buildSample "SealUnseal").overrideAttrs (old: {
    prePatch = ''
      substituteInPlace App/App.cpp \
        --replace '"sealed_data_blob.txt"' '"/tmp/sealed_data_blob.txt"'
    '';
  });
  Switchless = buildSample "Switchless";
  # # Requires SGX-patched openssl (sgxssl) build
  # sampleAttestedTLS = buildSample "SampleAttestedTLS";
} // lib.optionalAttrs (!isSimulation) {
  # # Requires kernel >= v6.2 && HW SGX
  # sampleAEXNotify = buildSample "SampleAEXNotify";

  # Requires HW SGX
  SampleCommonLoader = (buildSample "SampleCommonLoader").overrideAttrs (old: {
    nativeBuildInputs = [ sgx-psw ] ++ old.nativeBuildInputs;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,lib}
      mv sample app
      install -m 755 app $out/bin

      wrapProgram "$out/bin/app" \
        --chdir "$out/lib" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [sgx-psw]}"

      runHook postInstall
    '';
  });

  # # SEGFAULTs in simulation mode?
  # sampleEnclavePCL = buildSample "SampleEnclavePCL";
}).${sample}
