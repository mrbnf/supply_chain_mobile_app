import 'dart:ffi';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:hex/hex.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:supplychain/providers/authProvider.dart';
import 'package:supplychain/providers/coinProvider.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class SupplyChainProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  @override
  void dispose() {
    _client.dispose();

    super.dispose();
  }

  final String _rpcUrl = 'http://192.168.43.240:8545';
  final String _wsUrl = 'ws://192.168.43.240:8545/';
  late String _privateKey;
  late Web3Client _client;
  late String _abiCode;
  late Credentials _credentials;
  late EthereumAddress _contractAddress;
  late EthereumAddress? _publicAddress;
  late DeployedContract _contract;
  late List<String> _wilaya = [
    "Adrar",
    "Chlef",
    "Laghouat",
    "Oum El Bouaghi",
    "Batna",
    "Béjaïa",
    "Biskra",
    "Béchar",
    "Blida",
    "Bouira",
    "Tamanrasset",
    "Tébessa",
    "Tlemcen",
    "Tiaret",
    "Tizi Ouzou",
    "Alger",
    "Djelfa",
    "Jijel",
    "Sétif",
    "Saïda",
    "Skikda",
    "Sidi Bel Abbès",
    "Annaba",
    "Guelma",
    "Constantine",
    "Médéa",
    "Mostaganem",
    "M'Sila",
    "Mascara",
    "Ouargla",
    "Oran",
    "El bayadh",
    "Illizi",
    "Bordj Bou Arreridj",
    "Boumerdès",
    "El Tarf",
    "Tindouf",
    "Tissemsilt",
    "El Oued",
    "Khenchela",
    "Souk ahras",
    "Tipaza",
    "Mila",
    "Aïn Defla",
    "Naâma",
    "Aïn Témouchent",
    "Ghardaïa",
    "Relizane"
  ];
  late List<String> productssType = [
    "Potatoes",
    "Tomatoes",
    "Strawberries",
    "Plums",
    "Peaches",
    "Eggplant",
    "Cucumber",
    "Figs",
    "Onions",
    "Apples",
    "Cherries",
    "Broccoli",
    "Grapes",
    "Kiwi",
    "Lemons",
    "Oranges",
    "Spinach",
    "Carrots",
    "Lettuce",
    "Apricots"
  ];

  late ContractEvent _productAdded;
  late ContractFunction _farmerAddProduct;
  late ContractFunction _farmersProductsListe;
  //late ContractFunction _farmersProductsForSale;
  // late ContractFunction _farmersHistory;
  late ContractFunction _farmerConfirmSending;
  // late ContractFunction _farmersToSend;

  late ContractFunction _buyProductWholesaler;
  late ContractFunction _wholesalersProductsListe;
  // late ContractFunction _wholeSalerStock;
  // late ContractFunction _wholeSalerHistory;
  // late ContractFunction _wholeSalerproductsForSale;
  late ContractFunction _wholeSalerFromStockToSale;
  late ContractFunction _wholeSalerConfirmSending;
  // late ContractFunction _wholeSalerToSend;
  // late ContractFunction _wholeSalerToReceive;

  late ContractFunction _buyProductRetailer;
  late ContractFunction _retailersProductsListe;
  // late ContractFunction _retailerStock;
  // late ContractFunction _retailersproductsForSale;
  // late ContractFunction _retailerHistory;
  late ContractFunction _retailerFromStockToSale;
  late ContractFunction _retailerConfirmSending;
  // late ContractFunction _retailerToSend;
  // late ContractFunction _retailerToReceive;

  late ContractFunction _buyProductCustomers;
  // late ContractFunction _customersHistory;
  // late ContractFunction _customersToReceive;
  late ContractFunction _getHash;

  late ContractFunction _productsData;
  late ContractFunction _productDatafromList;
  late ContractFunction _farmersProductsPersonal;
  late ContractFunction _wholeSalerProductsPersonal;
  late ContractFunction _retailerProductsPersonal;
  late ContractFunction _customerProductsPersonal;
  late ContractFunction _modifyProduct;

  late ContractFunction _indexInListProduct;
  late ContractFunction _productTypes;
  late ContractEvent _productLocation;
  late ContractEvent _productBuyed;

  String aziz = 'aziz';

  bool isLogin = false;
  SupplyChainProvider(
    this._authProvider,
  ) {
    initiateSetup();
  }

  EthereumAddress get publicKey {
    return _publicAddress!;
  }

  List<String> get productsTypes {
    return productssType;
  }

  List<String> get wilayas {
    return _wilaya;
  }

  Future<void> lougout() async {
    isLogin = false;
  }

  Future<dynamic> getHash(BigInt id) async {
    final str = id.toString();
    final list = await _client
        .call(contract: _contract, function: _getHash, params: [str]);
    //print(list.toString());
    return list;
  }

  Future<String> singnMessage(BigInt id) async {
    final hash = await getHash(id);
    List<int> intList = hash[0].cast<int>().toList();
    Uint8List data = Uint8List.fromList(intList);
    // await getCredential(
    //     '6ed2bdb37da34db37134e98016de23da88c005312c0faa4c7f450206a3405f38');
    final signature = await _credentials.signPersonalMessage(data);
    //HEX.decode(
    // '4ca61667a6086c915d0bf1b542abd171bdf676d52eed640e514e984beed3fefe')
    //print(String.fromCharCodes(signature));
    //print(signature);

    //print(Uint8List.fromList(signature).buffer.asByteData().toString());
    String result = hex.encode(signature);
    print(result);
    //await farmerConfirmSending(id, signature, _coinProvider.contractAddress);
    //await wholeSalerConfirmSending(id, signature);

    return result;
  }

  Future<void> initiateSetup() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    //await getCredential();
    await getDeployedContract();
    //productssType = await productTypes();
  }

  Future<void> getCredentialfromPrivateKey(String _privateKeyy) async {
    await _client.credentialsFromPrivateKey(_privateKeyy);
  }

  Future<void> getCredential(String _privateKeyy) async {
    _credentials = await _client.credentialsFromPrivateKey(_privateKeyy);
    _publicAddress = await _credentials.extractAddress();
  }

  Future<void> getAbi() async {
    String abiStringFile =
        await rootBundle.loadString('assets/src/abis/SupplyChain.json');
    var jsonAbiCode = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbiCode['abi']);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbiCode['networks']['5777']['address']);
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, 'SupplyChain'), _contractAddress);

    _farmerAddProduct = _contract.function('farmerAddProduct');
    _farmersProductsListe = _contract.function('farmersProductsListe');
    // _farmersProductsForSale = _contract.function('farmersProductsForSale');
    // _farmersHistory = _contract.function('farmersHistory');

    _buyProductWholesaler = _contract.function('buyProductWholesaler');
    _wholesalersProductsListe = _contract.function('wholesalersProductsListe');
    // _wholeSalerStock = _contract.function('wholeSalerStock');
    // _wholeSalerHistory = _contract.function('wholeSalerHistory');
    // _wholeSalerproductsForSale =
    // _contract.function('wholeSalerproductsForSale');
    _wholeSalerFromStockToSale =
        _contract.function('wholeSalerFromStockToSale');

    _buyProductRetailer = _contract.function('buyProductRetailer');
    _retailersProductsListe = _contract.function('retailersProductsListe');
    // _retailerStock = _contract.function('retailerStock');
    // _retailersproductsForSale = _contract.function('retailersproductsForSale');
    // _retailerHistory = _contract.function('retailerHistory');
    _retailerFromStockToSale = _contract.function('retailerFromStockToSale');

    _buyProductCustomers = _contract.function('buyProductCustomers');
    // _customersHistory = _contract.function('customersHistory');
    _productsData = _contract.function('productsData');
    _productDatafromList = _contract.function('productDatafromList');
    _productAdded = _contract.event('ProductAdded');
    _productLocation = _contract.event('ProductLocation');
    _productBuyed = _contract.event('ProductBuyed');
    _farmerConfirmSending = _contract.function('farmerConfirmSending');
    _wholeSalerConfirmSending = _contract.function('wholeSalerConfirmSending');
    _retailerConfirmSending = _contract.function('retailerConfirmSending');
    // _farmersToSend = _contract.function('farmersToSend');
    // _wholeSalerToSend = _contract.function('wholeSalerToSend');
    // _wholeSalerToReceive = _contract.function('wholeSalerToReceive');
    // _retailerToSend = _contract.function('retailerToSend');
    // _retailerToReceive = _contract.function('retailerToReceive');
    // _customersToReceive = _contract.function('customersToReceive');
    _indexInListProduct = _contract.function('indexInListProduct');
    _productTypes = _contract.function('productTypes');
    _farmersProductsPersonal = _contract.function('farmersProductsPersonal');
    _wholeSalerProductsPersonal =
        _contract.function('wholeSalerProductsPersonal');
    _retailerProductsPersonal = _contract.function('retailerProductsPersonal');
    _customerProductsPersonal = _contract.function('customerProductsPersonal');
    _modifyProduct = _contract.function('modifyProduct');
    _getHash = _contract.function('getHash');
  }

  Future<List<BigInt>> customersToReceive(
      EthereumAddress _customerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _customerProductsPersonal,
        params: [_customerAddress, BigInt.from(4)]);
    List<BigInt> bigintList = list[0].cast<BigInt>();
    return bigintList;
  }

  Future<List<BigInt>> retailerToSend(EthereumAddress _retailerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _retailerProductsPersonal,
        params: [_retailerAddress, BigInt.from(3)]);
    List<BigInt> bigintList = list[0].cast<BigInt>();
    return bigintList;
  }

  Future<List<BigInt>> retailerToReceive(
      EthereumAddress _retailerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _retailerProductsPersonal,
        params: [_retailerAddress, BigInt.from(4)]);
    List<BigInt> bigintList = list[0].cast<BigInt>();
    return bigintList;
  }

  Future<List<BigInt>> wholeSalerToSend(
      EthereumAddress _wholesalerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _wholeSalerProductsPersonal,
        params: [_wholesalerAddress, BigInt.from(3)]);
    List<BigInt> bigintList = list[0].cast<BigInt>();
    return bigintList;
  }

  Future<List<BigInt>> wholeSalerToReceive(
      EthereumAddress _wholesalerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _wholeSalerProductsPersonal,
        params: [_wholesalerAddress, BigInt.from(4)]);
    List<BigInt> bigintList = list[0].cast<BigInt>();
    return bigintList;
  }

  Future<void> farmerConfirmSending(BigInt _productId, Uint8List _signature,
      EthereumAddress coinContractAddress) async {
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _farmerConfirmSending,
            parameters: [_productId, _signature, coinContractAddress]));
  }

  Future<void> wholeSalerConfirmSending(BigInt _productId, Uint8List _signature,
      EthereumAddress coinContractAddress) async {
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _wholeSalerConfirmSending,
            parameters: [_productId, _signature, coinContractAddress]));
  }

  Future<void> retailerConfirmSending(BigInt _productId, Uint8List _signature,
      EthereumAddress coinContractAddress) async {
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _retailerConfirmSending,
            parameters: [_productId, _signature, coinContractAddress]));
  }

  Future<List<dynamic>> getLocation(BigInt productId) async {
    final filter = FilterOptions(
        fromBlock: BlockNum.genesis(),
        toBlock: BlockNum.current(),
        address: _contract.address,
        topics: [
          ['0x' + hex.encode(_productLocation.signature)],
          [paddingTohex('0x' + productId.toRadixString(16))],
        ]);
    // print(BigInt.from(1002).toRadixString(16));
    //print('before');
    final l = await _client.getLogs(filter);
    //print(l);
    var p;
    List<dynamic> lD = [];
    for (var e in l) {
      p = _productLocation.decodeResults(e.topics!, e.data!);
      lD.add(p);
    }

    //print('after');
    return lD;
  }

  Future<List<BigInt>> getHistorySelled(String adderAdress) async {
    final filter = FilterOptions(
        fromBlock: BlockNum.genesis(),
        toBlock: BlockNum.current(),
        address: _contract.address,
        topics: [
          ['0x' + hex.encode(_productBuyed.signature)],
          [paddingTohex(adderAdress)],
          []
        ]);

    final l = await _client.getLogs(filter);

    var p;
    List<BigInt> lD = [];
    for (var e in l) {
      p = _productBuyed.decodeResults(e.topics!, e.data!);
      lD.add(p[2]);
    }

    return lD;
  }

  Future<List<BigInt>> getHistoryBuyed(String adderAdress) async {
    final filter = FilterOptions(
        fromBlock: BlockNum.genesis(),
        toBlock: BlockNum.current(),
        address: _contract.address,
        topics: [
          ['0x' + hex.encode(_productBuyed.signature)],
          [],
          [paddingTohex(adderAdress)],
        ]);

    final l = await _client.getLogs(filter);

    var p;
    List<BigInt> lD = [];
    for (var e in l) {
      p = _productBuyed.decodeResults(e.topics!, e.data!);
      lD.add(p[2]);
    }

    return lD;
  }

  Future<List<dynamic>> getProductAdded(String adderAdress) async {
    final filter = FilterOptions(
        fromBlock: BlockNum.genesis(),
        toBlock: BlockNum.current(),
        address: _contract.address,
        topics: [
          ['0x' + hex.encode(_productAdded.signature)],
          [paddingTohex(adderAdress)],
        ]);
    // print('0x000000000000000000000000c20b5d103646ef084e6595b4f68af96afa2397d5'
    //     .length);
    // var li = '0xC20b5d103646Ef084e6595b4F68af96AFA2397d5';
    //print(paddingTohex('0xc20b5d103646ef084e6595b4f68af96afa2397d5'));

    // print(li);
    // print(li.length);
    // print(bytesToHex('0xC20b5d103646Ef084e6595b4F68af96AFA2397d5',
    //     padToEvenLength: true, include0x: true));
    //rint('before');
    final l = await _client.getLogs(filter);
    //print(l);
    var p;
    List<dynamic> lD = [];
    for (var e in l) {
      p = _productAdded.decodeResults(e.topics!, e.data!);
      lD.add(p);
    }

    //print('after');
    return lD;
    // bytesToHex(hex.decode(productId.toRadixString(16)),
    //     padToEvenLength: true, include0x: true);
    // final lis = await _client.events(
    //     FilterOptions.events(contract: _contract, event: _productLocation));

    // final p = _productLocation.decodeResults(event.topics!, event.data!);
    //   print(p);
    //   if (p[0].toString() == productId.toString()) {
    //     location = p[1];
    //     print(location);
    //   }
    //   return p[0].toString() == productId.toString();
    //print(lis);

    //     .take(1)
    //     .listen((event) {
    //   final p = _farmerProductEvent.decodeResults(event.topics!, event.data!);
    //   print(p);
    // });
  }

  String paddingTohex(String text) {
    var t = text.toLowerCase();
    if (text.length < 66) {
      t = text.substring(0, 2) + '0' * (66 - text.length) + text.substring(2);
    }
    return t;
  }

  Future<BigInt> farmerAddProduct(String _type, BigInt _amount, BigInt _price,
      BigInt _minAmount, String _location) async {
    // final lis = _client
    //     .events(FilterOptions.events(
    //         contract: _contract, event: _farmerProductEvent))
    //     .take(1)
    //     .listen((event) {
    //   final p = _farmerProductEvent.decodeResults(event.topics!, event.data!);
    //   print(p);
    // });

    // lis.asFuture();
    late List p;
    final idData = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _farmerAddProduct,
            parameters: [_type, _amount, _price, _minAmount, _location]));
    final data = await _client.getTransactionReceipt(idData).then((event) {
      p = _productAdded.decodeResults(
          event!.logs[0].topics!, event.logs[0].data!);
      // print(p);
    });
    return BigInt.parse(p[1].toString());
  }

  Future<List<BigInt>> farmersProductsListe(String _productType) async {
    final list = await _client.call(
      contract: _contract,
      function: _farmersProductsListe,
      params: [_productType],
    );

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  Future<List<BigInt>> farmersProductsForSale(
      EthereumAddress _farmerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _farmersProductsPersonal,
        params: [_farmerAddress, BigInt.from(1)]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  // Future<List<BigInt>> farmersHistory(EthereumAddress _farmerAddress) async {
  //   final list = await _client.call(
  //       contract: _contract,
  //       function: _farmersHistory,
  //       params: [_farmerAddress]);

  //   List<BigInt> bigintList = list[0].cast<BigInt>();

  //   return bigintList;
  // }

  Future<List<BigInt>> farmersToSend(EthereumAddress _farmerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _farmersProductsPersonal,
        params: [_farmerAddress, BigInt.from(3)]);
    List<BigInt> bigintList = list[0].cast<BigInt>();
    return bigintList;
  }

  Future<List<BigInt>> wholesalersProductsListe(String _productType) async {
    final list = await _client.call(
        contract: _contract,
        function: _wholesalersProductsListe,
        params: [_productType]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  Future<List<BigInt>> wholeSalerproductsForSale(
      EthereumAddress _wholesalerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _wholeSalerProductsPersonal,
        params: [_wholesalerAddress, BigInt.from(1)]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  Future<List<BigInt>> wholeSalerStock(
      EthereumAddress _wholesalerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _wholeSalerProductsPersonal,
        params: [_wholesalerAddress, BigInt.from(2)]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  // Future<List<BigInt>> wholeSalerHistory(
  //     EthereumAddress _wholesalerAddress) async {
  //   final list = await _client.call(
  //       contract: _contract,
  //       function: _wholeSalerHistory,
  //       params: [_wholesalerAddress]);

  //   List<BigInt> bigintList = list[0].cast<BigInt>();

  //   return bigintList;
  // }

  Future<void> buyProductWholesaler(BigInt _productId, BigInt _amount,
      EthereumAddress coinContractAddress) async {
    try {
      await _client.sendTransaction(
          _credentials,
          Transaction.callContract(
              contract: _contract,
              function: _buyProductWholesaler,
              parameters: [_productId, _amount, coinContractAddress]));
    } catch (erreur) {
      rethrow;
    }
  }

  Future<void> wholeSalerFromStockToSale(BigInt _productId, BigInt _price,
      BigInt _minQuantity, String _location) async {
    try {
      await _client.sendTransaction(
          _credentials,
          Transaction.callContract(
              contract: _contract,
              function: _wholeSalerFromStockToSale,
              parameters: [_productId, _price, _minQuantity, _location]));
    } catch (erreur) {
      rethrow;
    }
  }

  Future<List<BigInt>> retailersProductsListe(String _productType) async {
    final list = await _client.call(
        contract: _contract,
        function: _retailersProductsListe,
        params: [_productType]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  Future<List<BigInt>> retailersproductsForSale(
      EthereumAddress _retailersAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _retailerProductsPersonal,
        params: [_retailersAddress, BigInt.from(1)]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  Future<List<BigInt>> retailerStock(EthereumAddress _retailerAddress) async {
    final list = await _client.call(
        contract: _contract,
        function: _retailerProductsPersonal,
        params: [_retailerAddress, BigInt.from(2)]);

    List<BigInt> bigintList = list[0].cast<BigInt>();

    return bigintList;
  }

  // Future<List<BigInt>> retailerHistory(EthereumAddress _retailerAddress) async {
  //   final list = await _client.call(
  //       contract: _contract,
  //       function: _retailerHistory,
  //       params: [_retailerAddress]);

  //   List<BigInt> bigintList = list[0].cast<BigInt>();

  //   return bigintList;
  // }

  Future<void> buyProductRetailer(BigInt _productId, BigInt _amount,
      EthereumAddress coinContractAddress) async {
    try {
      await _client.sendTransaction(
          _credentials,
          Transaction.callContract(
              contract: _contract,
              function: _buyProductRetailer,
              parameters: [_productId, _amount, coinContractAddress]));
    } catch (erreur) {
      rethrow;
    }
  }

  Future<void> retailerFromStockToSale(BigInt _productId, BigInt _price,
      BigInt _minQuantity, String _location) async {
    try {
      await _client.sendTransaction(
          _credentials,
          Transaction.callContract(
              contract: _contract,
              function: _retailerFromStockToSale,
              parameters: [_productId, _price, _minQuantity, _location]));
    } catch (erreur) {
      rethrow;
    }
  }

  Future<void> buyProductCustomers(BigInt _productId, BigInt _amount,
      EthereumAddress coinContractAddress) async {
    try {
      await _client.sendTransaction(
          _credentials,
          Transaction.callContract(
              contract: _contract,
              function: _buyProductCustomers,
              parameters: [_productId, _amount, coinContractAddress]));
    } catch (erreur) {
      rethrow;
    }
  }

  // Future<List<BigInt>> customersHistory(
  //     EthereumAddress _retailerAddress) async {
  //   final list = await _client.call(
  //       contract: _contract,
  //       function: _customersHistory,
  //       params: [_retailerAddress]);

  //   List<BigInt> bigintList = list[0].cast<BigInt>();

  //   return bigintList;
  // }

  Future<dynamic> productsData(BigInt id) async {
    final list = await _client
        .call(contract: _contract, function: _productsData, params: [id]);
    //print(list.toString());
    return list;
  }

  Future<List<dynamic>> productDatafromList(List<BigInt> _listId) async {
    final list = await _client.call(
        contract: _contract, function: _productDatafromList, params: [_listId]);
    return list[0];
  }

  Future<List<dynamic>> searchTracability(BigInt productId) async {
    dynamic data;
    List<String> dataInfor;
    BigInt parent;
    List<dynamic> l2 = [];
    List<BigInt> list = [];
    list.add(productId);
    data = await productsData(productId);

    dataInfor =
        await _authProvider.getInformationFromPublicAddress(data[0].toString());

    data.add(dataInfor[0]);
    data.add(dataInfor[1]);
    data.add(dataInfor[2]);
    data.add(dataInfor[3]);

    // dataInfor = await _authProvider.getInformationFromPublicAddress(data[0]);
    // data.push(dataInfor['Familly Name']);
    // data.push(dataInfor['First Name']);
    l2.add(data);

    parent = data[1];
    while (parent != BigInt.zero) {
      list.add(parent);
      data = await productsData(parent);
      dataInfor = await _authProvider
          .getInformationFromPublicAddress(data[0].toString());

      data.add(dataInfor[0]);
      data.add(dataInfor[1]);
      data.add(dataInfor[2]);
      data.add(dataInfor[3]);
      // data.push(dataInfor['First Name']);
      l2.add(data);
      parent = data[1];
    }
    //l2 = await productDatafromList(list);
    //return list.reversed.toList();
    //print(l2);
    return l2;
  }

  Future<List<String>> getInformationFromPublicAddressParent(
      BigInt productId) async {
    dynamic data;
    BigInt parent;
    List<String> dataInfor;
    data = await productsData(productId);
    parent = data[1];
    data = await productsData(parent);
    dataInfor =
        await _authProvider.getInformationFromPublicAddress(data[0].toString());

    return dataInfor;
  }

  Future<BigInt> indexInListProduct(String _productType) async {
    final list = await _client.call(
        contract: _contract,
        function: _indexInListProduct,
        params: [_productType]);

    return list[0];
  }

  Future<void> modifyProduct(BigInt _productId, BigInt _amount, BigInt _price,
      BigInt _minQuantity) async {
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _modifyProduct,
            parameters: [_productId, _amount, _price, _minQuantity]));
  }

  dynamic generatePrivateKey() {
    Random rng = Random.secure(); //secure random number generator
    BigInt privKey = generateNewPrivateKey(rng);
    //print(privKey.toRadixString(16));
    Uint8List pubKey = privateKeyToPublic(privKey);
    //print(pubKey);
    Uint8List address =
        publicKeyToAddress(pubKey); //Deduces the address from the public key
    String addressHex = bytesToHex(address, //Address byte array
        include0x: true, //Include 0x prefix
        forcePadLength: 40 //Padded to 40 bytes
        );
    //print(addressHex);
    return [privKey.toRadixString(16), addressHex];
  }

  Future<void> sendEther(EthereumAddress receiver, int amount) async {
    await _client.sendTransaction(
      _credentials,
      Transaction(
        to: receiver,
        // gasPrice: EtherAmount.inWei(BigInt.one),
        // maxGas: 100000,
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, amount),
      ),
    );
    final l = await _client.getBalance(receiver);
    print(l.getInEther);
  }

  // Future<List<String>> productTypes() async {
  //   final list = await _client
  //       .call(contract: _contract, function: _productTypes, params: []);

  //   print(list);
  //   return list[0];
  // }

  // Future<void> ppp() async {
  //   final pproductssType = await productTypes();
  //   print(pproductssType);
  // }

  List<String> communeForWilaya(String wilaya) {
    switch (wilaya) {
      case "Adrar":
        {
          return [
            "Adrar",
            "Tamest",
            "Charouine",
            "Reggane",
            "Inozghmir",
            "Tit",
            "Ksar Kaddour",
            "Tsabit",
            "Timimoun",
            "Ouled Said",
            "Zaouiet Kounta",
            "Aoulef",
            "Timokten",
            "Tamentit",
            "Fenoughil",
            "Tinerkouk",
            "Deldoul",
            "Sali",
            "Akabli",
            "Metarfa",
            "O Ahmed Timmi",
            "Bouda",
            "Aougrout",
            "Talmine",
            "B Badji Mokhtar",
            "Sbaa",
            "Ouled Aissa",
            "Timiaouine"
          ];
        }
        break;

      case "Chlef":
        {
          return [
            "Chlef",
            "Tenes",
            "Benairia",
            "El Karimia",
            "Tadjna",
            "Taougrite",
            "Beni Haoua",
            "Sobha",
            "Harchoun",
            "Ouled Fares",
            "Sidi Akacha",
            "Boukadir",
            "Beni Rached",
            "Talassa",
            "Herenfa",
            "Oued Goussine",
            "Dahra",
            "Ouled Abbes",
            "Sendjas",
            "Zeboudja",
            "Oued Sly",
            "Abou El Hassen",
            "El Marsa",
            "Chettia",
            "Sidi Abderrahmane",
            "Moussadek",
            "El Hadjadj",
            "Labiod Medjadja",
            "Oued Fodda",
            "Ouled Ben Abdelkader",
            "Bouzghaia",
            "Ain Merane",
            "Oum Drou",
            "Breira",
            "Ben Boutaleb"
          ];
        }
        break;

      case "Laghouat":
        {
          return [
            "Laghouat",
            "Ksar El Hirane",
            "Benacer Ben Chohra",
            "Sidi Makhlouf",
            "Hassi Delaa",
            "Hassi R Mel",
            "Ain Mahdi",
            "Tadjmout",
            "Kheneg",
            "Gueltat Sidi Saad",
            "Ain Sidi Ali",
            "Beidha",
            "Brida",
            "El Ghicha",
            "Hadj Mechri",
            "Sebgag",
            "Taouiala",
            "Tadjrouna",
            "Aflou",
            "El Assafia",
            "Oued Morra",
            "Oued M Zi",
            "El Haouaita",
            "Sidi Bouzid"
          ];
        }
        break;

      case "Oum El Bouaghi":
        {
          return [
            "Oum El Bouaghi",
            "Ain Beida",
            "Ainmlila",
            "Behir Chergui",
            "El Amiria",
            "Sigus",
            "El Belala",
            "Ain Babouche",
            "Berriche",
            "Ouled Hamla",
            "Dhala",
            "Ain Kercha",
            "Hanchir Toumghani",
            "El Djazia",
            "Ain Diss",
            "Fkirina",
            "Souk Naamane",
            "Zorg",
            "El Fedjoudj Boughrar",
            "Ouled Zouai",
            "Bir Chouhada",
            "Ksar Sbahi",
            "Oued Nini",
            "Meskiana",
            "Ain Fekroune",
            "Rahia",
            "Ain Zitoun",
            "Ouled Gacem",
            "El Harmilia"
          ];
        }
        break;

      case "Batna":
        {
          return [
            "Batna",
            "Ghassira",
            "Maafa",
            "Merouana",
            "Seriana",
            "Menaa",
            "El Madher",
            "Tazoult",
            "Ngaous",
            "Guigba",
            "Inoughissen",
            "Ouyoun El Assafir",
            "Djerma",
            "Bitam",
            "Metkaouak",
            "Arris",
            "Kimmel",
            "Tilatou",
            "Ain Djasser",
            "Ouled Selam",
            "Tigherghar",
            "Ain Yagout",
            "Fesdis",
            "Sefiane",
            "Rahbat",
            "Tighanimine",
            "Lemsane",
            "Ksar Belezma",
            "Seggana",
            "Ichmoul",
            "Foum Toub",
            "Beni Foudhala El Hakania",
            "Oued El Ma",
            "Talkhamt",
            "Bouzina",
            "Chemora",
            "Oued Chaaba",
            "Taxlent",
            "Gosbat",
            "Ouled Aouf",
            "Boumagueur",
            "Barika",
            "Djezzar",
            "Tkout",
            "Ain Touta",
            "Hidoussa",
            "Teniet El Abed",
            "Oued Taga",
            "Ouled Fadel",
            "Timgad",
            "Ras El Aioun",
            "Chir",
            "Ouled Si Slimane",
            "Zanat El Beida",
            "Amdoukal",
            "Ouled Ammar",
            "El Hassi",
            "Lazrou",
            "Boumia",
            "Boulhilat",
            "Larbaa"
          ];
        }
        break;

      case "Bejaia":
        {
          return [
            "Bejaia",
            "Amizour",
            "Ferraoun",
            "Taourirt Ighil",
            "Chelata",
            "Tamokra",
            "Timzrit",
            "Souk El Thenine",
            "Mcisna",
            "Thinabdher",
            "Tichi",
            "Semaoun",
            "Kendira",
            "Tifra",
            "Ighram",
            "Amalou",
            "Ighil Ali",
            "Ifelain Ilmathen",
            "Toudja",
            "Darguina",
            "Sidi Ayad",
            "Aokas",
            "Beni Djellil",
            "Adekar",
            "Akbou",
            "Seddouk",
            "Tazmalt",
            "Ait Rizine",
            "Chemini",
            "Souk Oufella",
            "Taskriout",
            "Tibane",
            "Tala Hamza",
            "Barbacha",
            "Beni Ksila",
            "Ouzallaguen",
            "Bouhamza",
            "Beni Melikeche",
            "Sidi Aich",
            "El Kseur",
            "Melbou",
            "Akfadou",
            "Leflaye",
            "Kherrata",
            "Draa Kaid",
            "Tamridjet",
            "Ait Smail",
            "Boukhelifa",
            "Tizi Nberber",
            "Beni Maouch",
            "Oued Ghir",
            "Boudjellil"
          ];
        }
        break;

      case "Biskra":
        {
          return [
            "Biskra",
            "Oumache",
            "Branis",
            "Chetma",
            "Ouled Djellal",
            "Ras El Miaad",
            "Besbes",
            "Sidi Khaled",
            "Doucen",
            "Ech Chaiba",
            "Sidi Okba",
            "Mchouneche",
            "El Haouch",
            "Ain Naga",
            "Zeribet El Oued",
            "El Feidh",
            "El Kantara",
            "Ain Zaatout",
            "El Outaya",
            "Djemorah",
            "Tolga",
            "Lioua",
            "Lichana",
            "Ourlal",
            "Mlili",
            "Foughala",
            "Bordj Ben Azzouz",
            "Meziraa",
            "Bouchagroun",
            "Mekhadma",
            "El Ghrous",
            "El Hadjab",
            "Khanguet Sidinadji"
          ];
        }
        break;

      case "Bechar":
        {
          return [
            "Bechar",
            "Erg Ferradj",
            "Ouled Khoudir",
            "Meridja",
            "Timoudi",
            "Lahmar",
            "Beni Abbes",
            "Beni Ikhlef",
            "Mechraa Houari B",
            "Kenedsa",
            "Igli",
            "Tabalbala",
            "Taghit",
            "El Ouata",
            "Boukais",
            "Mogheul",
            "Abadla",
            "Kerzaz",
            "Ksabi",
            "Tamtert",
            "Beni Ounif"
          ];
        }
        break;
      case "Blida":
        {
          return [
            "Blida",
            "Chebli",
            "Bouinan",
            "Oued El Alleug",
            "Ouled Yaich",
            "Chrea",
            "El Affroun",
            "Chiffa",
            "Hammam Melouane",
            "Ben Khlil",
            "Soumaa",
            "Mouzaia",
            "Souhane",
            "Meftah",
            "Ouled Selama",
            "Boufarik",
            "Larbaa",
            "Oued Djer",
            "Beni Tamou",
            "Bouarfa",
            "Beni Mered",
            "Bougara",
            "Guerrouaou",
            "Ain Romana",
            "Djebabra"
          ];
        }
        break;

      case "Bouira":
        {
          return [
            "Bouira",
            "El Asnam",
            "Guerrouma",
            "Souk El Khemis",
            "Kadiria",
            "Hanif",
            "Dirah",
            "Ait Laaziz",
            "Taghzout",
            "Raouraoua",
            "Mezdour",
            "Haizer",
            "Lakhdaria",
            "Maala",
            "El Hachimia",
            "Aomar",
            "Chorfa",
            "Bordj Oukhriss",
            "El Adjiba",
            "El Hakimia",
            "El Khebouzia",
            "Ahl El Ksar",
            "Bouderbala",
            "Zbarbar",
            "Ain El Hadjar",
            "Djebahia",
            "Aghbalou",
            "Taguedit",
            "Ain Turk",
            "Saharidj",
            "Dechmia",
            "Ridane",
            "Bechloul",
            "Boukram",
            "Ain Bessam",
            "Bir Ghbalou",
            "Mchedallah",
            "Sour El Ghozlane",
            "Maamora",
            "Ouled Rached",
            "Ain Laloui",
            "Hadjera Zerga",
            "Ath Mansour",
            "El Mokrani",
            "Oued El Berdi"
          ];
        }
        break;

      case "Tamanghasset":
        {
          return [
            "Tamanghasset",
            "Abalessa",
            "In Ghar",
            "In Guezzam",
            "Idles",
            "Tazouk",
            "Tinzaouatine",
            "In Salah",
            "In Amguel",
            "Foggaret Ezzaouia"
          ];
        }
        break;

      case "Tebessa":
        {
          return [
            "Tebessa",
            "Bir El Ater",
            "Cheria",
            "Stah Guentis",
            "El Aouinet",
            "Lahouidjbet",
            "Safsaf El Ouesra",
            "Hammamet",
            "Negrine",
            "Bir El Mokadem",
            "El Kouif",
            "Morsott",
            "El Ogla",
            "Bir Dheheb",
            "El Ogla El Malha",
            "Gorriguer",
            "Bekkaria",
            "Boukhadra",
            "Ouenza",
            "El Ma El Biodh",
            "Oum Ali",
            "Thlidjene",
            "Ain Zerga",
            "El Meridj",
            "Boulhaf Dyr",
            "Bedjene",
            "El Mazeraa",
            "Ferkane"
          ];
        }
        break;

      case "Tlemcen":
        {
          return [
            "Tlemcen",
            "Beni Mester",
            "Ain Tallout",
            "Remchi",
            "El Fehoul",
            "Sabra",
            "Ghazaouet",
            "Souani",
            "Djebala",
            "El Gor",
            "Oued Chouly",
            "Ain Fezza",
            "Ouled Mimoun",
            "Amieur",
            "Ain Youcef",
            "Zenata",
            "Beni Snous",
            "Bab El Assa",
            "Dar Yaghmouracene",
            "Fellaoucene",
            "Azails",
            "Sebbaa Chioukh",
            "Terni Beni Hediel",
            "Bensekrane",
            "Ain Nehala",
            "Hennaya",
            "Maghnia",
            "Hammam Boughrara",
            "Souahlia",
            "Msirda Fouaga",
            "Ain Fetah",
            "El Aricha",
            "Souk Thlata",
            "Sidi Abdelli",
            "Sebdou",
            "Beni Ouarsous",
            "Sidi Medjahed",
            "Beni Boussaid",
            "Marsa Ben Mhidi",
            "Nedroma",
            "Sidi Djillali",
            "Beni Bahdel",
            "El Bouihi",
            "Honaine",
            "Tianet",
            "Ouled Riyah",
            "Bouhlou",
            "Souk El Khemis",
            "Ain Ghoraba",
            "Chetouane",
            "Mansourah",
            "Beni Semiel",
            "Ain Kebira"
          ];
        }
        break;

      case "Tiaret":
        {
          return [
            "Tiaret",
            "Medroussa",
            "Ain Bouchekif",
            "Sidi Ali Mellal",
            "Ain Zarit",
            "Ain Deheb",
            "Sidi Bakhti",
            "Medrissa",
            "Zmalet El Emir Aek",
            "Madna",
            "Sebt",
            "Mellakou",
            "Dahmouni",
            "Rahouia",
            "Mahdia",
            "Sougueur",
            "Sidi Abdelghani",
            "Ain El Hadid",
            "Ouled Djerad",
            "Naima",
            "Meghila",
            "Guertoufa",
            "Sidi Hosni",
            "Djillali Ben Amar",
            "Sebaine",
            "Tousnina",
            "Frenda",
            "Ain Kermes",
            "Ksar Chellala",
            "Rechaiga",
            "Nadorah",
            "Tagdemt",
            "Oued Lilli",
            "Mechraa Safa",
            "Hamadia",
            "Chehaima",
            "Takhemaret",
            "Sidi Abderrahmane",
            "Serghine",
            "Bougara",
            "Faidja",
            "Tidda"
          ];
        }
        break;

      case "Tizi Ouzou":
        {
          return [
            "Tizi Ouzou",
            "Ain El Hammam",
            "Akbil",
            "Freha",
            "Souamaa",
            "Mechtrass",
            "Irdjen",
            "Timizart",
            "Makouda",
            "Draa El Mizan",
            "Tizi Ghenif",
            "Bounouh",
            "Ait Chaffaa",
            "Frikat",
            "Beni Aissi",
            "Beni Zmenzer",
            "Iferhounene",
            "Azazga",
            "Iloula Oumalou",
            "Yakouren",
            "Larba Nait Irathen",
            "Tizi Rached",
            "Zekri",
            "Ouaguenoun",
            "Ain Zaouia",
            "Mkira",
            "Ait Yahia",
            "Ait Mahmoud",
            "Maatka",
            "Ait Boumehdi",
            "Abi Youcef",
            "Beni Douala",
            "Illilten",
            "Bouzguen",
            "Ait Aggouacha",
            "Ouadhia",
            "Azzefoun",
            "Tigzirt",
            "Ait Aissa Mimoun",
            "Boghni",
            "Ifigha",
            "Ait Oumalou",
            "Tirmitine",
            "Akerrou",
            "Yatafen",
            "Beni Ziki",
            "Draa Ben Khedda",
            "Ouacif",
            "Idjeur",
            "Mekla",
            "Tizi Nthlata",
            "Beni Yenni",
            "Aghrib",
            "Iflissen",
            "Boudjima",
            "Ait Yahia Moussa",
            "Souk El Thenine",
            "Ait Khelil",
            "Sidi Naamane",
            "Iboudraren",
            "Aghni Goughran",
            "Mizrana",
            "Imsouhal",
            "Tadmait",
            "Ait Bouadou",
            "Assi Youcef",
            "Ait Toudert"
          ];
        }
        break;

      case "Alger":
        {
          return [
            "Alger Centre",
            "Sidi Mhamed",
            "El Madania",
            "Hamma Anassers",
            "Bab El Oued",
            "Bologhine Ibn Ziri",
            "Casbah",
            "Oued Koriche",
            "Bir Mourad Rais",
            "El Biar",
            "Bouzareah",
            "Birkhadem",
            "El Harrach",
            "Baraki",
            "Oued Smar",
            "Bourouba",
            "Hussein Dey",
            "Kouba",
            "Bachedjerah",
            "Dar El Beida",
            "Bab Azzouar",
            "Ben Aknoun",
            "Dely Ibrahim",
            "Bains Romains",
            "Rais Hamidou",
            "Djasr Kasentina",
            "El Mouradia",
            "Hydra",
            "Mohammadia",
            "Bordj El Kiffan",
            "El Magharia",
            "Beni Messous",
            "Les Eucalyptus",
            "Birtouta",
            "Tassala El Merdja",
            "Ouled Chebel",
            "Sidi Moussa",
            "Ain Taya",
            "Bordj El Bahri",
            "Marsa",
            "Haraoua",
            "Rouiba",
            "Reghaia",
            "Ain Benian",
            "Staoueli",
            "Zeralda",
            "Mahelma",
            "Rahmania",
            "Souidania",
            "Cheraga",
            "Ouled Fayet",
            "El Achour",
            "Draria",
            "Douera",
            "Baba Hassen",
            "Khracia",
            "Saoula"
          ];
        }
        break;

      case "Djelfa":
        {
          return [
            "Djelfa",
            "Moudjebara",
            "El Guedid",
            "Hassi Bahbah",
            "Ain Maabed",
            "Sed Rahal",
            "Feidh El Botma",
            "Birine",
            "Bouira Lahdeb",
            "Zaccar",
            "El Khemis",
            "Sidi Baizid",
            "Mliliha",
            "El Idrissia",
            "Douis",
            "Hassi El Euch",
            "Messaad",
            "Guettara",
            "Sidi Ladjel",
            "Had Sahary",
            "Guernini",
            "Selmana",
            "Ain Chouhada",
            "Oum Laadham",
            "Dar Chouikh",
            "Charef",
            "Beni Yacoub",
            "Zaafrane",
            "Deldoul",
            "Ain El Ibel",
            "Ain Oussera",
            "Benhar",
            "Hassi Fedoul",
            "Amourah",
            "Ain Fekka",
            "Tadmit"
          ];
        }
        break;

      case "Jijel":
        {
          return [
            "Jijel",
            "Erraguene",
            "El Aouana",
            "Ziamma Mansouriah",
            "Taher",
            "Emir Abdelkader",
            "Chekfa",
            "Chahna",
            "El Milia",
            "Sidi Maarouf",
            "Settara",
            "El Ancer",
            "Sidi Abdelaziz",
            "Kaous",
            "Ghebala",
            "Bouraoui Belhadef",
            "Djmila",
            "Selma Benziada",
            "Boussif Ouled Askeur",
            "El Kennar Nouchfi",
            "Ouled Yahia Khadrouch",
            "Boudria Beni Yadjis",
            "Kemir Oued Adjoul",
            "Texena",
            "Djemaa Beni Habibi",
            "Bordj Taher",
            "Ouled Rabah",
            "Ouadjana"
          ];
        }
        break;

      case "Setif":
        {
          return [
            "Setif",
            "Ain El Kebira",
            "Beni Aziz",
            "Ouled Sidi Ahmed",
            "Boutaleb",
            "Ain Roua",
            "Draa Kebila",
            "Bir El Arch",
            "Beni Chebana",
            "Ouled Tebben",
            "Hamma",
            "Maaouia",
            "Ain Legraj",
            "Ain Abessa",
            "Dehamcha",
            "Babor",
            "Guidjel",
            "Ain Lahdjar",
            "Bousselam",
            "El Eulma",
            "Djemila",
            "Beni Ouartilane",
            "Rosfa",
            "Ouled Addouane",
            "Belaa",
            "Ain Arnat",
            "Amoucha",
            "Ain Oulmane",
            "Beidha Bordj",
            "Bouandas",
            "Bazer Sakhra",
            "Hammam Essokhna",
            "Mezloug",
            "Bir Haddada",
            "Serdj El Ghoul",
            "Harbil",
            "El Ouricia",
            "Tizi Nbechar",
            "Salah Bey",
            "Ain Azal",
            "Guenzet",
            "Talaifacene",
            "Bougaa",
            "Beni Fouda",
            "Tachouda",
            "Beni Mouhli",
            "Ouled Sabor",
            "Guellal",
            "Ain Sebt",
            "Hammam Guergour",
            "Ait Naoual Mezada",
            "Ksar El Abtal",
            "Beni Hocine",
            "Ait Tizi",
            "Maouklane",
            "Guelta Zerka",
            "Oued El Barad",
            "Taya",
            "El Ouldja",
            "Tella"
          ];
        }
        break;

      case "Saida":
        {
          return [
            "Saida",
            "Doui Thabet",
            "Ain El Hadjar",
            "Ouled Khaled",
            "Moulay Larbi",
            "Youb",
            "Hounet",
            "Sidi Amar",
            "Sidi Boubekeur",
            "El Hassasna",
            "Maamora",
            "Sidi Ahmed",
            "Ain Sekhouna",
            "Ouled Brahim",
            "Tircine",
            "Ain Soltane"
          ];
        }
        break;

      case "Skikda":
        {
          return [
            "Skikda",
            "Ain Zouit",
            "El Hadaik",
            "Azzaba",
            "Djendel Saadi Mohamed",
            "Ain Cherchar",
            "Bekkouche Lakhdar",
            "Benazouz",
            "Es Sebt",
            "Collo",
            "Beni Zid",
            "Kerkera",
            "Ouled Attia",
            "Oued Zehour",
            "Zitouna",
            "El Harrouch",
            "Zerdazas",
            "Ouled Hebaba",
            "Sidi Mezghiche",
            "Emdjez Edchich",
            "Beni Oulbane",
            "Ain Bouziane",
            "Ramdane Djamel",
            "Beni Bachir",
            "Salah Bouchaour",
            "Tamalous",
            "Ain Kechra",
            "Oum Toub",
            "Bein El Ouiden",
            "Fil Fila",
            "Cheraia",
            "Kanoua",
            "El Ghedir",
            "Bouchtata",
            "Ouldja Boulbalout",
            "Kheneg Mayoum",
            "Hamadi Krouma",
            "El Marsa"
          ];
        }
        break;

      case "Sidi Bel Abbes":
        {
          return [
            "Sidi Bel Abbes",
            "Tessala",
            "Sidi Brahim",
            "Mostefa Ben Brahim",
            "Telagh",
            "Mezaourou",
            "Boukhanafis",
            "Sidi Ali Boussidi",
            "Badredine El Mokrani",
            "Marhoum",
            "Tafissour",
            "Amarnas",
            "Tilmouni",
            "Sidi Lahcene",
            "Ain Thrid",
            "Makedra",
            "Tenira",
            "Moulay Slissen",
            "El Hacaiba",
            "Hassi Zehana",
            "Tabia",
            "Merine",
            "Ras El Ma",
            "Ain Tindamine",
            "Ain Kada",
            "Mcid",
            "Sidi Khaled",
            "Ain El Berd",
            "Sfissef",
            "Ain Adden",
            "Oued Taourira",
            "Dhaya",
            "Zerouala",
            "Lamtar",
            "Sidi Chaib",
            "Sidi Dahou Dezairs",
            "Oued Sbaa",
            "Boudjebaa El Bordj",
            "Sehala Thaoura",
            "Sidi Yacoub",
            "Sidi Hamadouche",
            "Belarbi",
            "Oued Sefioun",
            "Teghalimet",
            "Ben Badis",
            "Sidi Ali Benyoub",
            "Chetouane Belaila",
            "Bir El Hammam",
            "Taoudmout",
            "Redjem Demouche",
            "Benachiba Chelia",
            "Hassi Dahou"
          ];
        }
        break;

      case "Annaba":
        {
          return [
            "Annaba",
            "Berrahel",
            "El Hadjar",
            "Eulma",
            "El Bouni",
            "Oued El Aneb",
            "Cheurfa",
            "Seraidi",
            "Ain Berda",
            "Chetaibi",
            "Sidi Amer",
            "Treat"
          ];
        }
        break;

      case "Guelma":
        {
          return [
            "Guelma",
            "Nechmaya",
            "Bouati Mahmoud",
            "Oued Zenati",
            "Tamlouka",
            "Oued Fragha",
            "Ain Sandel",
            "Ras El Agba",
            "Dahouara",
            "Belkhir",
            "Ben Djarah",
            "Bou Hamdane",
            "Ain Makhlouf",
            "Ain Ben Beida",
            "Khezara",
            "Beni Mezline",
            "Bou Hachana",
            "Guelaat Bou Sbaa",
            "Hammam Maskhoutine",
            "El Fedjoudj",
            "Bordj Sabat",
            "Hamman Nbail",
            "Ain Larbi",
            "Medjez Amar",
            "Bouchegouf",
            "Heliopolis",
            "Ain Hessania",
            "Roknia",
            "Salaoua Announa",
            "Medjez Sfa",
            "Boumahra Ahmed",
            "Ain Reggada",
            "Oued Cheham",
            "Djeballah Khemissi"
          ];
        }
        break;

      case "Constantine":
        {
          return [
            "Constantine",
            "Hamma Bouziane",
            "El Haria",
            "Zighoud Youcef",
            "Didouche Mourad",
            "El Khroub",
            "Ain Abid",
            "Beni Hamiden",
            "Ouled Rahmoune",
            "Ain Smara",
            "Mesaoud Boudjeriou",
            "Ibn Ziad"
          ];
        }
        break;

      case "Medea":
        {
          return [
            "Medea",
            "Ouzera",
            "Ouled Maaref",
            "Ain Boucif",
            "Aissaouia",
            "Ouled Deide",
            "El Omaria",
            "Derrag",
            "El Guelbelkebir",
            "Bouaiche",
            "Mezerena",
            "Ouled Brahim",
            "Damiat",
            "Sidi Ziane",
            "Tamesguida",
            "El Hamdania",
            "Kef Lakhdar",
            "Chelalet El Adhaoura",
            "Bouskene",
            "Rebaia",
            "Bouchrahil",
            "Ouled Hellal",
            "Tafraout",
            "Baata",
            "Boghar",
            "Sidi Naamane",
            "Ouled Bouachra",
            "Sidi Zahar",
            "Oued Harbil",
            "Benchicao",
            "Sidi Damed",
            "Aziz",
            "Souagui",
            "Zoubiria",
            "Ksar El Boukhari",
            "El Azizia",
            "Djouab",
            "Chahbounia",
            "Meghraoua",
            "Cheniguel",
            "Ain Ouksir",
            "Oum El Djalil",
            "Ouamri",
            "Si Mahdjoub",
            "Tlatet Eddoair",
            "Beni Slimane",
            "Berrouaghia",
            "Seghouane",
            "Meftaha",
            "Mihoub",
            "Boughezoul",
            "Tablat",
            "Deux Bassins",
            "Draa Essamar",
            "Sidi Errabia",
            "Bir Ben Laabed",
            "El Ouinet",
            "Ouled Antar",
            "Bouaichoune",
            "Hannacha",
            "Sedraia",
            "Medjebar",
            "Khams Djouamaa",
            "Saneg"
          ];
        }
        break;

      case "Mostaganem":
        {
          return [
            "Mostaganem",
            "Sayada",
            "Fornaka",
            "Stidia",
            "Ain Nouissy",
            "Hassi Maameche",
            "Ain Tadles",
            "Sour",
            "Oued El Kheir",
            "Sidi Bellater",
            "Kheiredine ",
            "Sidi Ali",
            "Abdelmalek Ramdane",
            "Hadjadj",
            "Nekmaria",
            "Sidi Lakhdar",
            "Achaacha",
            "Khadra",
            "Bouguirat",
            "Sirat",
            "Ain Sidi Cherif",
            "Mesra",
            "Mansourah",
            "Souaflia",
            "Ouled Boughalem",
            "Ouled Maallah",
            "Mezghrane",
            "Ain Boudinar",
            "Tazgait",
            "Safsaf",
            "Touahria",
            "El Hassiane"
          ];
        }
        break;

      case "Msila":
        {
          return [
            "Msila",
            "Maadid",
            "Hammam Dhalaa",
            "Ouled Derradj",
            "Tarmount",
            "Mtarfa",
            "Khoubana",
            "Mcif",
            "Chellal",
            "Ouled Madhi",
            "Magra",
            "Berhoum",
            "Ain Khadra",
            "Ouled Addi Guebala",
            "Belaiba",
            "Sidi Aissa",
            "Ain El Hadjel",
            "Sidi Hadjeres",
            "Ouanougha",
            "Bou Saada",
            "Ouled Sidi Brahim",
            "Sidi Ameur",
            "Tamsa",
            "Ben Srour",
            "Ouled Slimane",
            "El Houamed",
            "El Hamel",
            "Ouled Mansour",
            "Maarif",
            "Dehahna",
            "Bouti Sayah",
            "Khettouti Sed Djir",
            "Zarzour",
            "Oued Chair",
            "Benzouh",
            "Bir Foda",
            "Ain Fares",
            "Sidi Mhamed",
            "Ouled Atia",
            "Souamaa",
            "Ain El Melh",
            "Medjedel",
            "Slim",
            "Ain Errich",
            "Beni Ilmane",
            "Oultene",
            "Djebel Messaad"
          ];
        }
        break;

      case "Mascara":
        {
          return [
            "Mascara",
            "Bou Hanifia",
            "Tizi",
            "Hacine",
            "Maoussa",
            "Teghennif",
            "El Hachem",
            "Sidi Kada",
            "Zelmata",
            "Oued El Abtal",
            "Ain Ferah",
            "Ghriss",
            "Froha",
            "Matemore",
            "Makdha",
            "Sidi Boussaid",
            "El Bordj",
            "Ain Fekan",
            "Benian",
            "Khalouia",
            "El Menaouer",
            "Oued Taria",
            "Aouf",
            "Ain Fares",
            "Ain Frass",
            "Sig",
            "Oggaz",
            "Alaimia",
            "El Gaada",
            "Zahana",
            "Mohammadia",
            "Sidi Abdelmoumene",
            "Ferraguig",
            "El Ghomri",
            "Sedjerara",
            "Moctadouz",
            "Bou Henni",
            "Guettena",
            "El Mamounia",
            "El Keurt",
            "Gharrous",
            "Gherdjoum",
            "Chorfa",
            "Ras Ain Amirouche",
            "Nesmot",
            "Sidi Abdeldjebar",
            "Sehailia"
          ];
        }
        break;

      case "Ouargla":
        {
          return [
            "Ouargla",
            "Ain Beida",
            "Ngoussa",
            "Hassi Messaoud",
            "Rouissat",
            "Balidat Ameur",
            "Tebesbest",
            "Nezla",
            "Zaouia El Abidia",
            "Sidi Slimane",
            "Sidi Khouiled",
            "Hassi Ben Abdellah",
            "Touggourt",
            "El Hadjira",
            "Taibet",
            "Tamacine",
            "Benaceur",
            "Mnaguer",
            "Megarine",
            "El Allia",
            "El Borma"
          ];
        }
        break;

      case "Oran":
        {
          return [
            "Oran",
            "Gdyel",
            "Bir El Djir",
            "Hassi Bounif",
            "Es Senia",
            "Arzew",
            "Bethioua",
            "Marsat El Hadjadj",
            "Ain Turk",
            "El Ancar",
            "Oued Tlelat",
            "Tafraoui",
            "Sidi Chami",
            "Boufatis",
            "Mers El Kebir",
            "Bousfer",
            "El Karma",
            "El Braya",
            "Hassi Ben Okba",
            "Ben Freha",
            "Hassi Mefsoukh",
            "Sidi Ben Yabka",
            "Messerghin",
            "Boutlelis",
            "Ain Kerma",
            "Ain Biya"
          ];
        }
        break;

      case "El Bayadh":
        {
          return [
            "El Bayadh",
            "Rogassa",
            "Stitten",
            "Brezina",
            "Ghassoul",
            "Boualem",
            "El Abiodh Sidi Cheikh",
            "Ain El Orak",
            "Arbaouat",
            "Bougtoub",
            "El Kheither",
            "Kef El Ahmar",
            "Boussemghoun",
            "Chellala",
            "Krakda",
            "El Bnoud",
            "Cheguig",
            "Sidi Ameur",
            "El Mehara",
            "Tousmouline",
            "Sidi Slimane",
            "Sidi Tifour"
          ];
        }
        break;
      case "Illizi":
        {
          return [
            "Illizi",
            "Djanet",
            "Debdeb",
            "Bordj Omar Driss",
            "Bordj El Haouasse",
            "In Amenas"
          ];
        }
        break;

      case "Bordj Bou Arreridj":
        {
          return [
            "Bordj Bou Arreridj",
            "Ras El Oued",
            "Bordj Zemoura",
            "Mansoura",
            "El Mhir",
            "Ben Daoud",
            "El Achir",
            "Ain Taghrout",
            "Bordj Ghdir",
            "Sidi Embarek",
            "El Hamadia",
            "Belimour",
            "Medjana",
            "Teniet En Nasr",
            "Djaafra",
            "El Main",
            "Ouled Brahem",
            "Ouled Dahmane",
            "Hasnaoua",
            "Khelil",
            "Taglait",
            "Ksour",
            "Ouled Sidi Brahim",
            "Tafreg",
            "Colla",
            "Tixter",
            "El Ach",
            "El Anseur",
            "Tesmart",
            "Ain Tesra",
            "Bir Kasdali",
            "Ghilassa",
            "Rabta",
            "Haraza"
          ];
        }
        break;

      case "Boumerdes":
        {
          return [
            "Boumerdes",
            "Boudouaou",
            "Afir",
            "Bordj Menaiel",
            "Baghlia",
            "Sidi Daoud",
            "Naciria",
            "Djinet",
            "Isser",
            "Zemmouri",
            "Si Mustapha",
            "Tidjelabine",
            "Chabet El Ameur",
            "Thenia",
            "Timezrit",
            "Corso",
            "Ouled Moussa",
            "Larbatache",
            "Bouzegza Keddara",
            "Taourga",
            "Ouled Aissa",
            "Ben Choud",
            "Dellys",
            "Ammal",
            "Beni Amrane",
            "Souk El Had",
            "Boudouaou El Bahri",
            "Ouled Hedadj",
            "Laghata",
            "Hammedi",
            "Khemis El Khechna",
            "El Kharrouba"
          ];
        }
        break;

      case "El Tarf":
        {
          return [
            "El Tarf",
            "Bouhadjar",
            "Ben Mhidi",
            "Bougous",
            "El Kala",
            "Ain El Assel",
            "El Aioun",
            "Bouteldja",
            "Souarekh",
            "Berrihane",
            "Lac Des Oiseaux",
            "Chefia",
            "Drean",
            "Chihani",
            "Chebaita Mokhtar",
            "Besbes",
            "Asfour",
            "Echatt",
            "Zerizer",
            "Zitouna",
            "Ain Kerma",
            "Oued Zitoun",
            "Hammam Beni Salah",
            "Raml Souk"
          ];
        }
        break;

      case "Tindouf":
        {
          return ["Tindouf", "Oum El Assel"];
        }
        break;

      case "Tissemsilt":
        {
          return [
            "Tissemsilt",
            "Bordj Bou Naama",
            "Theniet El Had",
            "Lazharia",
            "Beni Chaib",
            "Lardjem",
            "Melaab",
            "Sidi Lantri",
            "Bordj El Emir Abdelkader",
            "Layoune",
            "Khemisti",
            "Ouled Bessem",
            "Ammari",
            "Youssoufia",
            "Sidi Boutouchent",
            "Larbaa",
            "Maasem",
            "Sidi Abed",
            "Tamalaht",
            "Sidi Slimane",
            "Boucaid",
            "Beni Lahcene"
          ];
        }
        break;

      case "El Oued":
        {
          return [
            "El Oued",
            "Robbah",
            "Oued El Alenda",
            "Bayadha",
            "Nakhla",
            "Guemar",
            "Kouinine",
            "Reguiba",
            "Hamraia",
            "Taghzout",
            "Debila",
            "Hassani Abdelkrim",
            "Hassi Khelifa",
            "Taleb Larbi",
            "Douar El Ma",
            "Sidi Aoun",
            "Trifaoui",
            "Magrane",
            "Beni Guecha",
            "Ourmas",
            "Still",
            "Mrara",
            "Sidi Khellil",
            "Tendla",
            "El Ogla",
            "Mih Ouansa",
            "El Mghair",
            "Djamaa",
            "Oum Touyour",
            "Sidi Amrane"
          ];
        }
        break;

      case "Khenchela":
        {
          return [
            "Khenchela",
            "Mtoussa",
            "Kais",
            "Baghai",
            "El Hamma",
            "Ain Touila",
            "Taouzianat",
            "Bouhmama",
            "El Oueldja",
            "Remila",
            "Cherchar",
            "Djellal",
            "Babar",
            "Tamza",
            "Ensigha",
            "Ouled Rechache",
            "El Mahmal",
            "Msara",
            "Yabous",
            "Khirane",
            "Chelia"
          ];
        }
        break;

      case "Souk Ahras":
        {
          return [
            "Souk Ahras",
            "Sedrata",
            "Hanancha",
            "Mechroha",
            "Ouled Driss",
            "Tiffech",
            "Zaarouria",
            "Taoura",
            "Drea",
            "Haddada",
            "Khedara",
            "Merahna",
            "Ouled Moumen",
            "Bir Bouhouche",
            "Mdaourouche",
            "Oum El Adhaim",
            "Ain Zana",
            "Ain Soltane",
            "Quillen",
            "Sidi Fredj",
            "Safel El Ouiden",
            "Ragouba",
            "Khemissa",
            "Oued Keberit",
            "Terraguelt",
            "Zouabi"
          ];
        }
        break;

      case "Tipaza":
        {
          return [
            "Tipaza",
            "Menaceur",
            "Larhat",
            "Douaouda",
            "Bourkika",
            "Khemisti",
            "Aghabal",
            "Hadjout",
            "Sidi Amar",
            "Gouraya",
            "Nodor",
            "Chaiba",
            "Ain Tagourait",
            "Cherchel",
            "Damous",
            "Meurad",
            "Fouka",
            "Bou Ismail",
            "Ahmer El Ain",
            "Bou Haroun",
            "Sidi Ghiles",
            "Messelmoun",
            "Sidi Rached",
            "Kolea",
            "Attatba",
            "Sidi Semiane",
            "Beni Milleuk",
            "Hadjerat Ennous"
          ];
        }
        break;

      case "Mila":
        {
          return [
            "Mila",
            "Ferdjioua",
            "Chelghoum Laid",
            "Oued Athmenia",
            "Ain Mellouk",
            "Telerghma",
            "Oued Seguen",
            "Tadjenanet",
            "Benyahia Abderrahmane",
            "Oued Endja",
            "Ahmed Rachedi",
            "Ouled Khalouf",
            "Tiberguent",
            "Bouhatem",
            "Rouached",
            "Tessala Lamatai",
            "Grarem Gouga",
            "Sidi Merouane",
            "Tassadane Haddada",
            "Derradji Bousselah",
            "Minar Zarza",
            "Amira Arras",
            "Terrai Bainen",
            "Hamala",
            "Ain Tine",
            "El Mechira",
            "Sidi Khelifa",
            "Zeghaia",
            "Elayadi Barbes",
            "Ain Beida Harriche",
            "Yahia Beniguecha",
            "Chigara"
          ];
        }
        break;

      case "Ain Defla":
        {
          return [
            "Ain Defla",
            "Miliana",
            "Boumedfaa",
            "Khemis Miliana",
            "Hammam Righa",
            "Arib",
            "Djelida",
            "El Amra",
            "Bourached",
            "El Attaf",
            "El Abadia",
            "Djendel",
            "Oued Chorfa",
            "Ain Lechiakh",
            "Oued Djemaa",
            "Rouina",
            "Zeddine",
            "El Hassania",
            "Bir Ouled Khelifa",
            "Ain Soltane",
            "Tarik Ibn Ziad",
            "Bordj Emir Khaled",
            "Ain Torki",
            "Sidi Lakhdar",
            "Ben Allal",
            "Ain Benian",
            "Hoceinia",
            "Barbouche",
            "Djemaa Ouled Chikh",
            "Mekhatria",
            "Bathia",
            "Tachta Zegagha",
            "Ain Bouyahia",
            "El Maine",
            "Tiberkanine",
            "Belaas"
          ];
        }
        break;
      case "Naama":
        {
          return [
            "Naama",
            "Mechria",
            "Ain Sefra",
            "Tiout",
            "Sfissifa",
            "Moghrar",
            "Assela",
            "Djeniane Bourzeg",
            "Ain Ben Khelil",
            "Makman Ben Amer",
            "Kasdir",
            "El Biod"
          ];
        }
        break;

      case "Ain Temouchent":
        {
          return [
            "Ain Temouchent",
            "Chaabet El Ham",
            "Ain Kihal",
            "Hammam Bouhadjar",
            "Bou Zedjar",
            "Oued Berkeche",
            "Aghlal",
            "Terga",
            "Ain El Arbaa",
            "Tamzoura",
            "Chentouf",
            "Sidi Ben Adda",
            "Aoubellil",
            "El Malah",
            "Sidi Boumediene",
            "Oued Sabah",
            "Ouled Boudjemaa",
            "Ain Tolba",
            "El Amria",
            "Hassi El Ghella",
            "Hassasna",
            "Ouled Kihal",
            "Beni Saf",
            "Sidi Safi",
            "Oulhaca El Gheraba",
            "Tadmaya",
            "El Emir Abdelkader",
            "El Messaid"
          ];
        }
        break;

      case "Ghardaia":
        {
          return [
            "Ghardaia",
            "El Meniaa",
            "Dhayet Bendhahoua",
            "Berriane",
            "Metlili",
            "El Guerrara",
            "El Atteuf",
            "Zelfana",
            "Sebseb",
            "Bounoura",
            "Hassi Fehal",
            "Hassi Gara",
            "Mansoura"
          ];
        }
        break;

      case "Relizane":
        {
          return [
            "Relizane",
            "Oued Rhiou",
            "Belaassel Bouzegza",
            "Sidi Saada",
            "Ouled Aiche",
            "Sidi Lazreg",
            "El Hamadna",
            "Sidi Mhamed Ben Ali",
            "Mediouna",
            "Sidi Khettab",
            "Ammi Moussa",
            "Zemmoura",
            "Beni Dergoun",
            "Djidiouia",
            "El Guettar",
            "Hamri",
            "El Matmar",
            "Sidi Mhamed Ben Aouda",
            "Ain Tarek",
            "Oued Essalem",
            "Ouarizane",
            "Mazouna",
            "Kalaa",
            "Ain Rahma",
            "Yellel",
            "Oued El Djemaa",
            "Ramka",
            "Mendes",
            "Lahlef",
            "Beni Zentis",
            "Souk El Haad",
            "Dar Ben Abdellah",
            "El Hassi",
            "Had Echkalla",
            "Bendaoud",
            "El Ouldja",
            "Merdja Sidi Abed",
            "Ouled Sidi Mihoub"
          ];
        }
        break;

      default:
        {
          return [];
        }
        break;
    }
  }
}
