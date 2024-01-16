# Reproducible SGX enclaves

This project demostrates how to reproducibly build SGX enclaves with Nix and Nixpkgs.
To learn more, read the [Enhancing trust for SGX enclaves](https://blog.trailofbits.com/2024/01/26/enhancing-trust-for-sgx-enclaves/) blog post.

## How to use

1. Clone the repository:
```
$ git clone https://github.com/trailofbits/reproducible-sgx
$ cd reproducible-sgx
```

2. [Install Nix](https://nixos.org/download) on your system or run Nix in Docker:
```
$ docker run --rm -it -v $(pwd):/reproducible-sgx -w /reproducible-sgx nixos/nix
```

3. Build a sample enclave and check its measurement hash (MRENCLAVE):
```
$ nix-build
$ ls result
$ less result/enclave_metadata.txt
...
metadata->enclave_css.body.enclave_hash.m:
0x7e 0x8f 0x29 0xff 0xb0 0x5e 0x80 0x64 0x35 0xef 0x3b 0xcd 0xa8 0x7b 0x86 0xab
0xd9 0xdc 0xe7 0x65 0x28 0xcf 0xd3 0x2a 0x01 0x7c 0xc7 0x8f 0xa5 0xba 0xe4 0x92
...
```

By default, the [SampleEnclave](https://github.com/intel/linux-sgx/tree/242644c77764fe46da2f86f352f4fdca349f2926/SampleCode/SampleEnclave) example is built in simulation mode.
Use `nix-build --arg sample '"RemoteAttestation"'` to build another sample.
