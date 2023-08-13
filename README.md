# Cross Carat

Cross chain unified messaging interface to enable universal communication between any two EVM-based blockchains.

<img width="1440" alt="Screenshot 2023-08-13 at 8 01 50 PM" src="https://github.com/saurabh-lodha-16/cross-carat/assets/47684949/7a2af8e5-c2a0-4daa-94ec-6611dfe85e48">


## Project Architecture

![zblocks_flow drawio (1)](https://github.com/saurabh-lodha-16/cross-carat/assets/47684949/b05e70cf-71e6-406b-8c9e-e6bef832ef3d)

### Steps to setup this project.

#### Clone Project Codebase

```
git clone https://github.com/saurabh-lodha-16/cross-carat.git
```

#### Install dependencies

```
yarn
```

#### Create a .env file in root folder and paste the following. You can also use .env.example for reference

```
PRIVATE_KEY=
POLYGON_MUMBAI_RPC_URL=
POLYGONSCAN_API_KEY=
OPTIMISM_GOERLI_RPC_URL=
OPTIMISMSCAN_API_KEY=
BASESCAN_API_KEY=
BASE_GOERLI_RPC_URL=
```

#### Compile

```
yarn run compile
```


### Deployed and Used Contracts

#### Polygon Mumbai - 

```

LayerZeroFacet : 0x19b3015e1498Da7eCc54f6058256573B1a613544
HyperlaneFacet : 0x427E1E0Bba5FF54e1D11907896db9c4310367306
CCIPFacet : 0x73984f66cCa05342eEEdbbD6378da721C741eb8E

Diamond deployed: 0xD1FaE79D5836d6A8456AE8B081A7053d91157A03
Wrapper Contract: 0x0900CE0d2b6E889b65dDea621726A000acDF7C8B

```
Optimism Goerli - 

```

LayerZeroFacet : 0x658Ae166e26bBD81f653C8087e1A0806EE26dB80
HyperlaneFacet : 0xa683DB531AEE7968A89EaA396AFC5BEbFF885e27
CCIPFacet : 0x8a467DE43Ba4C996bafC4e30E38049D97bDfe6aE

Diamond deployed: 0x6537f4f568159B7b42E7878915b1f104b91a9951
Wrapper Contract: 0xB823b09D759D2f802bebF6c63Dd3473d7D840B52

```

Base Goerli - 

```

LayerZeroFacet : 0xd13a389cE2130230Fbd919829fe2175B089ac3BC

Diamond deployed: 0x34fa80e9797163707775824105585aaD84336195
Wrapper Contract: 0x247a2b4db0de577E60a2b478E89eeC1A2646e7e7

```




