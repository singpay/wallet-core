// Copyright © 2017-2020 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
import WalletCore

class BitcoinTransactionSignerTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }
    
    func testSignBrc20Transfer() throws {
        // Successfully broadcasted: https://www.blockchain.com/explorer/transactions/btc/3e3576eb02667fac284a5ecfcb25768969680cc4c597784602d0a33ba7c654b7
        let privateKeyData = Data(hexString: "e253373989199da27c48680e3a3fc0f648d50f9a727ef17a7fe6a4dc3b159129")!
        let fullAmount = 26400 as Int64;
        let minerFee = 3000 as Int64;
        let brcInscribeAmount = 7000 as Int64;
        let dustSatoshis = 546 as Int64
        let forFeeAmount = fullAmount - brcInscribeAmount - minerFee;
        let txIdInscription = Data.reverse(hexString: "7046dc2689a27e143ea2ad1039710885147e9485ab6453fa7e87464aa7dd3eca");
        let txIDForFees = Data.reverse(hexString: "797d17d47ae66e598341f9dfdea020b04d4017dcf9cc33f0e51f7a6082171fb1");
        
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)
        let pubKeyHash = publicKey.bitcoinKeyHash
        let bobPubkeyHash = PublicKey(data: Data(hexString: "02f453bb46e7afc8796a9629e89e07b5cb0867e9ca340b571e7bcc63fc20c43f2e")!, type: .secp256k1)!.bitcoinKeyHash
        let p2wpkh = BitcoinScript.buildPayToWitnessPubkeyHash(hash: pubKeyHash)
        let outputP2wpkh = BitcoinScript.buildPayToWitnessPubkeyHash(hash: bobPubkeyHash)
        
        var input = BitcoinSigningInput.with {
            $0.isItBrcOperation = true
            $0.privateKey = [privateKeyData]
        }
        let utxo0 = BitcoinUnspentTransaction.with {
            $0.script = p2wpkh.data
            $0.amount = dustSatoshis
            $0.variant = .p2Wpkh
            $0.outPoint.hash = txIdInscription
            $0.outPoint.index = 0
        }
        let utxo1 = BitcoinUnspentTransaction.with {
            $0.script = p2wpkh.data
            $0.amount = forFeeAmount
            $0.variant = .p2Wpkh
            $0.outPoint.hash = txIDForFees
            $0.outPoint.index = 1
        }
        input.utxo.append(utxo0)
        input.utxo.append(utxo1)
        
        let utxos = [
            BitcoinUnspentTransaction.with {
                $0.script = outputP2wpkh.data
                $0.amount = dustSatoshis
                $0.variant = .p2Wpkh
            },
            BitcoinUnspentTransaction.with {
                $0.script = p2wpkh.data
                $0.amount = forFeeAmount - minerFee
                $0.variant = .p2Wpkh
            }
        ]

        let plan = BitcoinTransactionPlan.with {
            $0.utxos = utxos
        }
        input.plan = plan
        
        let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)
        let transactionId = output.transactionID
        XCTAssertEqual(transactionId, "3e3576eb02667fac284a5ecfcb25768969680cc4c597784602d0a33ba7c654b7")
        let encoded = output.encoded
        XCTAssertEqual(encoded.hexString, "02000000000102ca3edda74a46877efa5364ab85947e148508713910ada23e147ea28926dc46700000000000ffffffffb11f1782607a1fe5f033ccf9dc17404db020a0dedff94183596ee67ad4177d790100000000ffffffff022202000000000000160014e891850afc55b64aa8247b2076f8894ebdf889015834000000000000160014e311b8d6ddff856ce8e9a4e03bc6d4fe5050a83d024830450221008798393eb0b7390217591a8c33abe18dd2f7ea7009766e0d833edeaec63f2ec302200cf876ff52e68dbaf108a3f6da250713a9b04949a8f1dcd1fb867b24052236950121030f209b6ada5edb42c77fd2bc64ad650ae38314c8f451f3e36d80bc8e26f132cb0248304502210096bbb9d1f0596d69875646689e46f29485e8ceccacde9d0025db87fd96d3066902206d6de2dd69d965d28df3441b94c76e812384ab9297e69afe3480ee4031e1b2060121030f209b6ada5edb42c77fd2bc64ad650ae38314c8f451f3e36d80bc8e26f132cb00000000");
    }
    
    func testSignBrc20Commit() throws {
        // Successfully broadcasted: https://www.blockchain.com/explorer/transactions/btc/797d17d47ae66e598341f9dfdea020b04d4017dcf9cc33f0e51f7a6082171fb1
        let privateKeyData = Data(hexString: "e253373989199da27c48680e3a3fc0f648d50f9a727ef17a7fe6a4dc3b159129")!
        let fullAmount = 26400 as Int64;
        let minerFee = 3000 as Int64;
        let brcInscribeAmount = 7000 as Int64;
        let forFeeAmount = fullAmount - brcInscribeAmount - minerFee;
        let txId = Data(hexString: "089098890d2653567b9e8df2d1fbe5c3c8bf1910ca7184e301db0ad3b495c88e")!;
        
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)
        let pubKeyHash = publicKey.bitcoinKeyHash
        let p2wpkh = BitcoinScript.buildPayToWitnessPubkeyHash(hash: pubKeyHash)
        let outputInscribe = BitcoinScript.buildBRC20InscribeTransfer(ticker: "oadf", amount: "20", pubkey: publicKey.data)
        let outputProto = try BitcoinTransactionOutput(serializedData: outputInscribe)
        
        var input = BitcoinSigningInput.with {
            $0.isItBrcOperation = true
            $0.privateKey = [privateKeyData]
        }
        let utxo0 = BitcoinUnspentTransaction.with {
            $0.script = p2wpkh.data
            $0.amount = fullAmount
            $0.variant = .p2Wpkh
            $0.outPoint.hash = txId
            $0.outPoint.index = 1
        }
        input.utxo.append(utxo0)
        
        let utxos = [
            BitcoinUnspentTransaction.with {
                $0.script = outputProto.script
                $0.amount = brcInscribeAmount
                $0.variant = .brc20Transfer
            },
            BitcoinUnspentTransaction.with {
                $0.script = p2wpkh.data
                $0.amount = forFeeAmount
                $0.variant = .p2Wpkh
            }
        ]

        let plan = BitcoinTransactionPlan.with {
            $0.utxos = utxos
        }
        input.plan = plan
        
        let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)
        let transactionId = output.transactionID
        XCTAssertEqual(transactionId, "797d17d47ae66e598341f9dfdea020b04d4017dcf9cc33f0e51f7a6082171fb1")
        let encoded = output.encoded
        XCTAssertEqual(encoded.hexString, "02000000000101089098890d2653567b9e8df2d1fbe5c3c8bf1910ca7184e301db0ad3b495c88e0100000000ffffffff02581b000000000000225120e8b706a97732e705e22ae7710703e7f589ed13c636324461afa443016134cc051040000000000000160014e311b8d6ddff856ce8e9a4e03bc6d4fe5050a83d02483045022100a44aa28446a9a886b378a4a65e32ad9a3108870bd725dc6105160bed4f317097022069e9de36422e4ce2e42b39884aa5f626f8f94194d1013007d5a1ea9220a06dce0121030f209b6ada5edb42c77fd2bc64ad650ae38314c8f451f3e36d80bc8e26f132cb00000000");
    }
    
    func testSignBrc20Reveal() throws {
        // Successfully broadcasted: https://www.blockchain.com/explorer/transactions/btc/7046dc2689a27e143ea2ad1039710885147e9485ab6453fa7e87464aa7dd3eca
        let privateKeyData = Data(hexString: "e253373989199da27c48680e3a3fc0f648d50f9a727ef17a7fe6a4dc3b159129")!
        let dustSatoshis = 546 as Int64;
        let brcInscribeAmount = 7000 as Int64;
        let txId = Data(hexString: "b11f1782607a1fe5f033ccf9dc17404db020a0dedff94183596ee67ad4177d79")!;
        
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: false)
        let pubKeyHash = publicKey.bitcoinKeyHash
        let p2wpkh = BitcoinScript.buildPayToWitnessPubkeyHash(hash: pubKeyHash)
        let outputInscribe = BitcoinScript.buildBRC20InscribeTransfer(ticker: "oadf", amount: "20", pubkey: publicKey.data)
        let outputProto = try BitcoinTransactionOutput(serializedData: outputInscribe)
        
        var input = BitcoinSigningInput.with {
            $0.isItBrcOperation = true
            $0.privateKey = [privateKeyData]
        }
        let utxo0 = BitcoinUnspentTransaction.with {
            $0.script = outputProto.script
            $0.amount = brcInscribeAmount
            $0.variant = .brc20Transfer
            $0.spendingScript = outputProto.spendingScript
            $0.outPoint.hash = txId
            $0.outPoint.index = 0
        }
        input.utxo.append(utxo0)
        
        let utxos = [
            BitcoinUnspentTransaction.with {
                $0.script = p2wpkh.data
                $0.amount = dustSatoshis
                $0.variant = .p2Wpkh
            }
        ]

        let plan = BitcoinTransactionPlan.with {
            $0.utxos = utxos
        }
        input.plan = plan
        
        let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)
        let transactionId = output.transactionID
        XCTAssertEqual(transactionId, "7046dc2689a27e143ea2ad1039710885147e9485ab6453fa7e87464aa7dd3eca")
        let encoded = output.encoded
        XCTAssertTrue(encoded.hexString.hasPrefix("02000000000101b11f1782607a1fe5f033ccf9dc17404db020a0dedff94183596ee67ad4177d790000000000ffffffff012202000000000000160014e311b8d6ddff856ce8e9a4e03bc6d4fe5050a83d0340"));
        
        XCTAssertTrue(encoded.hexString.hasSuffix("5b0063036f7264010118746578742f706c61696e3b636861727365743d7574662d3800377b2270223a226272632d3230222c226f70223a227472616e73666572222c227469636b223a226f616466222c22616d74223a223230227d6821c00f209b6ada5edb42c77fd2bc64ad650ae38314c8f451f3e36d80bc8e26f132cb00000000"));
    }

    func testSignP2WSH() throws {
        // set up input
        var input = BitcoinSigningInput.with {
            $0.hashType = BitcoinScript.hashTypeForCoin(coinType: .bitcoin)
            $0.amount = 1000
            $0.byteFee = 1
            $0.toAddress = "1Bp9U1ogV3A14FMvKbRJms7ctyso4Z4Tcx"
            $0.changeAddress = "1FQc5LdgGHMHEN9nwkjmz6tWkxhPpxBvBU"
        }

        input.scripts["593128f9f90e38b706c18623151e37d2da05c229"] = Data(hexString: "2103596d3451025c19dbbdeb932d6bf8bfb4ad499b95b6f88db8899efac102e5fc71ac")!

        let p2sh = BitcoinScript.buildPayToWitnessScriptHash(scriptHash: Data(hexString: "ff25429251b5a84f452230a3c75fd886b7fc5a7865ce4a7bb7a9d7c5be6da3db")!)
        let utxo0 = BitcoinUnspentTransaction.with {
            $0.script = p2sh.data
            $0.amount = 1226
            $0.outPoint.hash = Data(hexString: "0001000000000000000000000000000000000000000000000000000000000000")!
            $0.outPoint.index = 0
            $0.outPoint.sequence = UInt32.max
        }
        input.utxo.append(utxo0)

        // Plan
        let plan: BitcoinTransactionPlan = AnySigner.plan(input: input, coin: .bitcoin)

        XCTAssertEqual(plan.amount, 1000)
        XCTAssertEqual(plan.fee, 147)
        XCTAssertEqual(plan.change, 79)

        // Extend input with private key
        input.privateKey.append(Data(hexString: "ed00a0841cd53aedf89b0c616742d1d2a930f8ae2b0fb514765a17bb62c7521a")!)
        input.privateKey.append(Data(hexString: "619c335025c7f4012e556c2a58b2506e30b8511b53ade95ea316fd8c3286feb9")!)

        // Sign
        let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)
        XCTAssertEqual(output.error, TW_Common_Proto_SigningError.ok)

        let signedTx = output.transaction
        XCTAssertEqual(signedTx.version, 1)

        let txId = output.transactionID
        XCTAssertEqual(txId, "dc60991ff61a6061f55854ce6fb3203b7c8291ed7b2ce799040114c608391583")

        XCTAssertEqual(signedTx.inputs.count, 1)  // Only one UTXO available
        XCTAssertEqual(signedTx.inputs[0].script.hexString, "")

        XCTAssertEqual(signedTx.outputs.count, 2) // Exact amount
        XCTAssertEqual(signedTx.outputs[0].value, 1000)
        XCTAssertEqual(signedTx.outputs[1].value, 79)

        let encoded = output.encoded
        let witnessHash = Data(Hash.sha256SHA256(data: encoded).reversed())
        XCTAssertEqual(witnessHash.hexString, "ec57de0d46eb45e8019b82e388e458e72fb834dba971e3a45ff8fa7bb7bdb799")
        XCTAssertEqual(encoded.hexString,
            "01000000" + // version
            "0001" + // marker & flag
            "01" + // inputs
                "0001000000000000000000000000000000000000000000000000000000000000" + "00000000" + "00" + "ffffffff" +
            "02" + // outputs
                "e803000000000000" + "19" + "76a914769bdff96a02f9135a1d19b749db6a78fe07dc9088ac" +
                "4f00000000000000" + "19" + "76a9149e089b6889e032d46e3b915a3392edfd616fb1c488ac" +
            // witness
                "02" +
                    "48" + "30450221009eefc1befe96158f82b74e6804f1f713768c6172636ca11fcc975c316ea86f75022057914c48bc24f717498b851a47a2926f96242e3943ebdf08d5a97a499efc8b9001" +
                    "23" + "2103596d3451025c19dbbdeb932d6bf8bfb4ad499b95b6f88db8899efac102e5fc71ac" +
            "00000000" // nLockTime
        )
    }

    func testSignP2SH_P2WPKH() {
        let address = "3LGoLac9mtCwDy2q8PYyvwL8kMyrCWCYQW"
        let lockScript = BitcoinScript.lockScriptForAddress(address: address, coin: .bitcoin)
        let key = PrivateKey(data: Data(hexString: "e240ef3419d038577e48426c8c37c3c13bec1a0ed3f5270b82e7377bc48699dd")!)!
        let pubkey = key.getPublicKeySecp256k1(compressed: true)
        let utxos = [
            BitcoinUnspentTransaction.with {
                $0.outPoint.hash = Data.reverse(hexString: "8b5f4861c6d4a4ea361aa4066d720067f73854d9a1b1d01e2b0e3c9e150bc5a3")
                $0.outPoint.index = 0
                $0.outPoint.sequence = UINT32_MAX
                $0.script = lockScript.data
                $0.amount = 54700
            }
        ]

        let plan = BitcoinTransactionPlan.with {
            $0.amount = 43980
            $0.fee = 10720
            $0.change = 0
            $0.utxos = utxos
        }

        // redeem p2wpkh nested in p2sh
        let scriptHash = lockScript.matchPayToScriptHash()!
        let input = BitcoinSigningInput.with {
            $0.amount = 43980
            $0.toAddress = "3NqULUrjZ7NL36YtBGsSVzqr5q1x9CJWwu"
            $0.hashType = BitcoinScript.hashTypeForCoin(coinType: .bitcoin)
            $0.coinType = CoinType.bitcoin.rawValue
            $0.scripts = [
                scriptHash.hexString: BitcoinScript.buildPayToWitnessPubkeyHash(hash: pubkey.bitcoinKeyHash).data
            ]
            $0.privateKey = [key.data]
            $0.plan = plan
        }

        let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)

        // https://blockchair.com/bitcoin/transaction/da2a9ce5d71ff7490bc9025e2888ca109b68ec0bd0e7d26195e1783305c00117
        XCTAssertEqual(output.encoded.hexString, "01000000000101a3c50b159e3c0e2b1ed0b1a1d95438f76700726d06a41a36eaa4d4c661485f8b00000000171600140a3cca78017f46ac23e463148adb7231aef81956ffffffff01ccab00000000000017a914e7f40472c54fc93078c5129568cf95c27be3b2c287024830450221008dc29a5430facd4078ad93e72517d87b298d7a73b55d2828acab040ccf713ed5022063a13e348655fa7cdcfff084380611629babf165607b529bcc35bf6ddfab1f8101210370386469db8302c3092955724f56bcca9a36f31df82655aa79be46b08744cd1200000000")
    }

    func testHashTypeForCoin() {
        XCTAssertEqual(BitcoinScript.hashTypeForCoin(coinType: .bitcoin), TWBitcoinSigHashTypeAll.rawValue)
        XCTAssertEqual(BitcoinScript.hashTypeForCoin(coinType: .bitcoinCash), 0x41)
        XCTAssertEqual(BitcoinScript.hashTypeForCoin(coinType: .bitcoinGold), 0x4f41)
    }

    func testSignExtendedPubkeyUTXO() {
        // compressed WIF, real key is 5KCr
        let wif = "L4BeKzm3AHDUMkxLRVKTSVxkp6Hz9FcMQPh18YCKU1uioXfovzwP"
        let decoded = Base58.decode(string: wif)!
        let key = PrivateKey(data: decoded[1 ..< 33])!
        let pubkey = key.getPublicKeySecp256k1(compressed: false)

        // shortcut methods only support compressed public key
        let address = BitcoinAddress(data: [0x0] + Hash.sha256RIPEMD(data: pubkey.data))!
        let script = BitcoinScript.lockScriptForAddress(address: address.description, coin: .bitcoin)

        // utxos from: https://blockchair.com/bitcoin/address/1KRhiKNai3ke3hZgSPZ5TpJoSJvs1aZfWo
        let utxos: [BitcoinUnspentTransaction] = [
            .with {
                $0.outPoint.hash = Data.reverse(hexString: "6ae3f1d245521b0ea7627231d27d613d58c237d6bf97a1471341a3532e31906c")
                $0.outPoint.index = 0
                $0.outPoint.sequence = UINT32_MAX
                $0.amount = 16874
                $0.script = script.data
            },
            .with {
                $0.outPoint.hash = Data.reverse(hexString: "fd1ea8178228e825d4106df0acb61a4fb14a8f04f30cd7c1f39c665c9427bf13")
                $0.outPoint.index = 0
                $0.outPoint.sequence = UINT32_MAX
                $0.amount = 10098
                $0.script = script.data
            }
        ]

        let input = BitcoinSigningInput.with {
            $0.utxo = utxos
            $0.privateKey = [key.data]
            $0.hashType = BitcoinScript.hashTypeForCoin(coinType: .bitcoin)
            $0.useMaxAmount = true
            $0.byteFee = 10
            $0.toAddress = "1FeyttPotRsSd4equWr678dbEvXaNSqmDT"
            $0.coinType = CoinType.bitcoin.rawValue
            $0.amount = utxos.map { $0.amount } .reduce(0, +)
        }

        let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)

        // https://blockchair.com/bitcoin/transaction/1d73706d33ec249beae6804c2e636ab9d7adbc2e9548757f6fcf8118771cb311
        XCTAssertEqual(output.error, .ok)
        XCTAssertEqual(output.encoded.hexString, "01000000026c90312e53a3411347a197bfd637c2583d617dd2317262a70e1b5245d2f1e36a000000008a47304402201a631068ea5ddea19467ef7c932a0f3b04f366ca2beaf70e18958e47456124980220614816c449e39cf6acc6625e1cf3100db1db7c0b755bdbb6804d4fa3c4b735d10141041b3937fac1f14074447cde9d3a324ed292d2865ed0d7a7da26cb43558ce4db4ef33c47e820e53031ae16bb0c39205def059a5ca8e1d617650eabc72c5206a81dffffffff13bf27945c669cf3c1d70cf3048f4ab14f1ab6acf06d10d425e8288217a81efd000000008a473044022051d381d8f48a9a4866ca4109f12647922514604a4733e8da8aac046e19275f700220797c3ebf20df7d2a9fed283f9d0ad14cbd656cafb5ec70a2b1c85646ea7485190141041b3937fac1f14074447cde9d3a324ed292d2865ed0d7a7da26cb43558ce4db4ef33c47e820e53031ae16bb0c39205def059a5ca8e1d617650eabc72c5206a81dffffffff0194590000000000001976a914a0c0a50f986924e65ae9bd18eafae448f83117ed88ac00000000")
    }

    func testBitcoinMessageSigner() {
        let verifyResult = BitcoinMessageSigner.verifyMessage(
            address: "1B8Qea79tsxmn4dTiKKRVvsJpHwL2fMQnr",
            message: "test signature",
            signature: "H+3L5IbSVcejp4S2VwLXCxLEMQAWDvKbE8lQyq0ocdvyM1aoEudkzN/S/qLI3vnNOFY6V13BXWSFrPr3OjGa5Dk="
        )
        XCTAssertTrue(verifyResult)
    }
}
