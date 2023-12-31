import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:page_transition/page_transition.dart';
import 'package:xiao_vpn/purchase_page/widgets/purchase_case_item.dart';
import 'package:xiao_vpn/purchase_page/widgets/supcription_item.dart';

import '../Component/text_style/text_styles.dart';
import '../model/app_image.dart';
import '../modules/browser_page/browser_page.dart';
import '../utils/colors.dart';
import '../utils/component/image_widget/svg_widget.dart';

const List<String> _kProductIds = <String>[
  'qksoft_sub_01',
  'qksoft_sub_02',
  'qksoft_sub_03',
  'qksoft_sub_04',
  'qksoft_sub_05',
  'qksoft_sub_06',
  'qksoft_sub_07',
  'qksoft_sub_08',
  'qksoft_sub_09',
  'qksoft_sub_10',
  'qksoft_sub_11',
  'qksoft_sub_12',
  'qksoft_sub_13',
  'qksoft_sub_14',
  'qksoft_sub_15',
  'qksoft_sub_16',
  'qksoft_sub_17',
  'qksoft_sub_18',
  'qksoft_sub_19'
];

class PurchaseV2Page extends StatefulWidget {
  const PurchaseV2Page({super.key});

  @override
  State<PurchaseV2Page> createState() => _PurchaseV2PageState();
}

class _PurchaseV2PageState extends State<PurchaseV2Page> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  String? _queryProductError;
  String? _selectedProductId;

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
    initStoreInfo();
    super.initState();
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isError = _queryProductError != null;

    if (isError) {
      return Container(
        color: AppColor.backgroundV2,
        child: Center(
          child: Text(
            'S.current.smthw',
            style: AppTextStyle.regular14.copyWith(color: AppColor.white),
          ),
        ),
      );
    }

    final List<Widget> productList = <Widget>[];

    if (_products.isEmpty) {
      productList.add(const SizedBox(
        height: 20,
      ));
    } else {
      productList.addAll(
        _products.mapIndexed(
          (index, product) => PurchaseCaseItem(
              value: product.price,
              duration: product.parseDuration(),
              onPressed: () => handlePurchaseButtonAsync(product),
              isSelected: _selectedProductId == product.id),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.backgroundV2,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.transparent,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(16).copyWith(bottom: 0),
              child: const SvgWidget(svgPath: SvgPath.close),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16).copyWith(top: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Premium Plan',
              style: AppTextStyle.regular30.copyWith(color: AppColor.green),
            ),
            const SizedBox(
              height: 44,
            ),
            Supcription(svgPath: SvgPath.unlock, title: 'Unlock VPN Location'),
            const SizedBox(
              height: 20,
            ),
            Supcription(svgPath: SvgPath.sub3, title: 'No ads'),
            const SizedBox(
              height: 44,
            ),
            Center(
              child: Text(
                _getSelectedProductDetails()?.parseDescription() ?? "",
                style:
                    AppTextStyle.regular14.copyWith(color: AppColor.unselected),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Column(
              children: productList,
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              'Payment will be charged to iTunes Account at confirmation of purchase. To ensure uninterrupted service, all subscriptions are renewed automatically unless auto-renew is turned off at least 24-hours before the end of the current period. The account is charged for renewal within 24-hours before the end of the current period. Users can manage and cancel subscriptions in their account settings on the App Store. Please note that when your purchase a subscription, the sale is final, and we will not provide a refund. Your purchase will be subject to Apple\'s applicable payment policy, which also may not provide for refunds.',
              style: AppTextStyle.regular11.copyWith(
                fontSize: 10,
                color: AppColor.unselected,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: handleTermButton,
                  child: Text(
                    'Term of Use',
                    style: AppTextStyle.regular13.copyWith(
                        color: AppColor.white,
                        decoration: TextDecoration.underline),
                  ),
                ),
                GestureDetector(
                  onTap: handleRestoreButtonAsync,
                  child: Text(
                    'Restore',
                    style: AppTextStyle.regular13.copyWith(
                        color: AppColor.white,
                        decoration: TextDecoration.underline),
                  ),
                ),
                GestureDetector(
                  onTap: handlePrivacyPolicyButton,
                  child: Text(
                    'Privacy Policy',
                    style: AppTextStyle.regular13.copyWith(
                        color: AppColor.white,
                        decoration: TextDecoration.underline),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
      });
      return;
    }

    if (Platform.isIOS) {
      final iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error?.message;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _selectedProductId = _products.firstOrNull?.id;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _selectedProductId = _products.firstOrNull?.id;
      });
      return;
    }

    setState(() {
      _products = productDetailResponse.productDetails;
      _selectedProductId = _products.firstOrNull?.id;
    });
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          EasyLoading.show();
          break;
        case PurchaseStatus.purchased:
          if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
          // await locator<AppDatabase>().setPastProduct(Product(
          //   expireDate: DateTime.now().add(Duration(
          //     days: 3 +
          //         ((purchaseDetails.productID == _weekId)
          //             ? 7
          //             : purchaseDetails.productID == _monthId
          //                 ? 30
          //                 : 365),
          //   )),
          //   productID: purchaseDetails.productID,
          // ));
          EasyLoading.showSuccess('S.current.unlock');
          break;
        case PurchaseStatus.error:
          if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
          EasyLoading.showError('S.current.unlock');
          break;
        case PurchaseStatus.restored:
          // await locator<AppDatabase>().setPastProduct(Product(
          //   expireDate: DateTime.fromMillisecondsSinceEpoch(
          //           int.parse(purchaseDetails.transactionDate.toString()))
          //       .add(Duration(
          //     days: 3 +
          //         ((purchaseDetails.productID == _weekId)
          //             ? 7
          //             : purchaseDetails.productID == _monthId
          //                 ? 30
          //                 : 365),
          //   )),
          //   productID: purchaseDetails.productID,
          // ));
          EasyLoading.showSuccess('S.current.unlock');
          break;
        case PurchaseStatus.canceled:
          // TODO: Handle this case.
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    setState(() {
      _purchases.add(purchaseDetails);
    });
  }

  ProductDetails? _getSelectedProductDetails() {
    return _products
        .firstWhereOrNull((element) => element.id == _selectedProductId);
  }

  setSelectedProductId(String id) {
    setState(() {
      _selectedProductId = id;
    });
  }

  showPendingUI() {
    setState(() {});
  }

  handleError(IAPError error) {
    setState(() {});
  }

  handlePurchaseButtonAsync(ProductDetails? productDetails) async {
    debugPrint("handlePurchaseButtonAsync() called");
    if (productDetails == null) {
      return;
    }

    late PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails, changeSubscriptionParam: null);
    } else {
      purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      var transactions = await SKPaymentQueueWrapper().transactions();
      for (var skPaymentTransactionWrapper in transactions) {
        await SKPaymentQueueWrapper()
            .finishTransaction(skPaymentTransactionWrapper);
      }
    }
    await _inAppPurchase
        .buyNonConsumable(purchaseParam: purchaseParam)
        .catchError((error) {
      EasyLoading.showError('S.current.unlock');
      return true;
    });
  }

  handleTermButton() {
    debugPrint("handleTermButtonTapped() called");
    Navigator.of(context).push(PageTransition(
        child: BrowserPage(
          url: 'https://sites.google.com/view/hello-vpn-fast-proxy',
          title: 'Term',
        ),
        type: PageTransitionType.rightToLeft));
  }

  handleRestoreButtonAsync() async {
    EasyLoading.show();
    await _inAppPurchase.restorePurchases().catchError((e) {
      if (e is SKError) {
        EasyLoading.showInfo(
            e.userInfo['NSLocalizedDescription'] ?? 'S.current.unlock');
      }
    });
    EasyLoading.dismiss();
  }

  handlePrivacyPolicyButton() {
    Navigator.of(context).push(PageTransition(
      child: BrowserPage(
          url: 'https://sites.google.com/view/hellovpn-fastproxy',
          title: 'Privacy Policy'),
      type: PageTransitionType.rightToLeft,
    ));
  }
}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information
/// needed to complete transactions.
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return false;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

extension ProductDetailsExt on ProductDetails {
  String parseDuration() {
    switch (id) {
      // case _weekId:
      //   return S.current.week;
      // case _monthId:
      //   return S.current.month;
      // case _yearId:
      //   return S.current.year;
      default:
        return "Undefine";
    }
  }

  String parseDescription() {
    String duration = parseDuration();
    return "${'S.current.unlock'} $price/$duration";
  }
}
