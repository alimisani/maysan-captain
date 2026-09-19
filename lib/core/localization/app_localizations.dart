import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      // App General
      'appName': 'كابتن ميسان',
      'appSlogan': 'خدمتكم شرفنا في محافظة ميسان',
      'maysanSpecialized': 'خاص بمحافظة ميسان وأقضيتها ونواحيها',
      'loading': 'جاري التحميل...',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'delete': 'حذف',
      'edit': 'تعديل',
      'search': 'بحث...',
      'filter': 'تصفية',
      'all': 'الكل',
      'error': 'حدث خطأ',
      'success': 'تمت العملية بنجاح',
      'retry': 'إعادة المحاولة',
      'noData': 'لا توجد بيانات حالياً',

      // Navigation & Sections
      'home': 'الرئيسية',
      'orders': 'الطلبات',
      'driverDashboard': 'لوحة الكابتن',
      'adminDashboard': 'لوحة الإدارة',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',

      // Auth
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب جديد',
      'name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'phone': 'رقم الهاتف',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'loginIdentifierHint': 'الاسم أو البريد الإلكتروني أو رقم الهاتف',
      'loginButton': 'دخول إلى التطبيق',
      'registerButton': 'إنشاء الحساب',
      'haveAccount': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'dontHaveAccount': 'ليس لديك حساب؟ إنشاء حساب جديد',
      'accountType': 'نوع الحساب',
      'passengerUser': 'زبون (راكب / صاحب طلب)',
      'captainDriver': 'كابتن (سائق مركبة)',
      'invalidCredentials': 'بيانات الدخول غير صحيحة، يرجى التأكد والمحاولة مجدداً',
      'fillAllFields': 'يرجى ملء جميع الحقول المطلوبة',
      'passwordsDontMatch': 'كلمات المرور غير متطابقة',

      // Map & Booking
      'rideService': 'توصيل ركاب (مشوار)',
      'deliveryService': 'توصيل طلبات (طرود)',
      'pickupLocation': 'مكان الانطلاق',
      'dropoffLocation': 'مكان الوصول',
      'selectPickup': 'حدد نقطة الانطلاق على الخريطة',
      'selectDropoff': 'حدد نقطة الوصول على الخريطة',
      'tapMapToSet': 'انقر على الخريطة أو حرك الدبوس لتحديد الموقع بدقة',
      'maysanLandmarks': 'معالم وأقضية ميسان السريعة',
      'estimatedFare': 'الأجرة المقدرة',
      'iqd': 'د.ع',
      'km': 'كم',
      'distance': 'المسافة التقريبية',
      'bookNow': 'طلب رحلة الآن',
      'requestDelivery': 'طلب التوصيل الآن',
      'packageNotes': 'ملاحظات الطلب أو وصف الطرد',
      'packageNotesHint': 'اكتب أي ملاحظات للوجهة أو وصف الشحنة...',
      'routeSummary': 'مسار الرحلة في ميسان',

      // Vehicles
      'vehicleType': 'نوع المركبة',
      'vehicleModel': 'موديل المركبة وسنة الصنع',
      'vehicleColor': 'لون المركبة',
      'plateNumber': 'رقم اللوحة',
      'registerVehicle': 'تسجيل المركبة',
      'myVehicles': 'مركباتي',
      'salonTaxi': 'صالون (تكسي)',
      'privateCar': 'سيارة خصوصي',
      'motorcycle': 'دراجة نارية للتوصيل',
      'tukTuk': 'ستوتة / تكتك',
      'pickupTruck': 'بيك آب / حمل شحن',
      'vipCar': 'سيارة VIP فارهة',

      // Statuses
      'statusPending': 'قيد الانتظار',
      'statusAccepted': 'تم قبول الطلب',
      'statusOnWay': 'الكابتن في الطريق إليك',
      'statusArrived': 'وصل الكابتن إلى مكان الانطلاق',
      'statusCompleted': 'اكتملت الرحلة بنجاح',
      'statusCancelled': 'ملغاة',

      // Driver Flow & Negotiation
      'incomingRequests': 'الطلبات المتاحة حالياً',
      'proposedFare': 'الأجرة المقترحة من الإدارة',
      'customFare': 'تعديل الأجرة لهذا الطلب',
      'acceptWithFare': 'قبول الطلب بالأجرة المحددة',
      'rejectOrder': 'رفض الطلب',
      'callCustomer': 'اتصال بالزبون',
      'whatsappCustomer': 'مراسلة عبر الواتساب',
      'callDriver': 'اتصال بالكابتن',
      'whatsappDriver': 'مراسلة الكابتن عبر الواتساب',
      'updateStatus': 'تحديث حالة الرحلة',
      'startTrip': 'بدء المسير إلى الوجهة',
      'completeTrip': 'إنهاء الرحلة واستلام الأجرة',
      'captainInfo': 'معلومات الكابتن',
      'customerInfo': 'معلومات الزبون',
      'rating': 'التقييم',
      'reviews': 'المراجعات',
      'rateTrip': 'تقييم الرحلة والكابتن',
      'submitRating': 'إرسال التقييم',
      'writeComment': 'اكتب تعليقك ورأيك في الخدمة...',

      // Invoices
      'invoice': 'فاتورة الرحلة',
      'exportPdf': 'تصدير فاتورة PDF',
      'printInvoice': 'طباعة الفاتورة',
      'shareInvoice': 'مشاركة الفاتورة',
      'invoiceNumber': 'رقم الفاتورة',
      'tripDate': 'تاريخ الرحلة',
      'totalAmount': 'المبلغ الإجمالي',
      'tripBreakdown': 'تفاصيل الأجرة والمسار',

      // Admin Dashboard
      'adminTitle': 'لوحة تحكم المدير العام',
      'totalUsers': 'إجمالي المستخدمين',
      'totalDrivers': 'إجمالي الكباتن',
      'totalRides': 'إجمالي الرحلات',
      'totalDeliveries': 'إجمالي الطلبات',
      'manageUsers': 'إدارة المستخدمين',
      'manageDrivers': 'إدارة الكباتن والمركبات',
      'manageOrders': 'إدارة الرحلات والطلبات',
      'pricingSettings': 'إعدادات التسعير',
      'baseFare': 'الأجرة الأساسية (د.ع)',
      'perKmRate': 'سعر الكيلومتر الواحد (د.ع)',
      'deliveryBaseFare': 'أجرة التوصيل الأساسية (د.ع)',
      'updatePricing': 'تحديث خطة الأسعار',

      // Settings
      'appSettings': 'إعدادات التطبيق',
      'changeFont': 'تغيير خط التطبيق',
      'selectedFont': 'الخط الحالي',
      'language': 'اللغة',
      'arabic': 'العربية (العراق)',
      'english': 'English',
      'appearance': 'المظهر',
      'darkMode': 'الوضع الليلي (Aurora Dark)',
      'lightMode': 'الوضع النهاري (Aurora Light)',
      'developerInfo': 'معلومات المطور',
      'devCompany': 'الشركة المطورة: ميسان تك - Maysan Tech',
      'devAuthor': 'المطور: علي سعدون الموسوي',
      'contactDeveloper': 'تواصل مع المطور',
      'visitWebsite': 'زيارة الموقع الرسمي',
      'logout': 'تسجيل الخروج',
      'logoutConfirm': 'هل أنت متأكد من تسجيل الخروج؟',

      // Extra UI Keys
      'captainOnline': 'كابتن متصل (جاهز للعمل)',
      'captainOffline': 'كابتن غير متصل (استراحة)',
      'availableOrders': 'طلبات متاحة',
      'availableCount': 'متاح',
      'acrossMaysan': 'في عموم محافظة ميسان',
      'openCaptainDashboard': 'فتح لوحة الكابتن والطلبات',
      'hello': 'أهلاً، ',
      'tapToSetDestination': 'انقر لتحديد الوجهة وطلب مشوار',
      'tapToRevealOptions': 'انقر لإظهار خيارات الطلب',
      'waitingForPassenger': 'بانتظار موافقة الراكب...',
      'proposedFareSent': 'تم إرسال عرض الأجرة للزبون. ستفتح نافذة التتبع تلقائياً فور موافقته.',
      'proposedFareDeclined': 'تم رفض الأجرة المقترحة من قبل الزبون، عاد الطلب للائحة',
      'cancelProposal': 'إلغاء العرض والرجوع',
      'passengerRide': 'توصيل ركاب',
      'packageDelivery': 'توصيل طرد / طلب',
      'noPendingOrders': 'لا توجد طلبات جديدة حالياً في ميسان',
      'pullToRefresh': 'اسحب الشاشة للأسفل للتحديث',
      'manageSubscription': 'تعديل الاشتراك',
      'lifetimeSub': '👑 اشتراك دائمي (مدى الحياة)',
      'annualSub': '📅 اشتراك سنوي',
      'expiredSub': '⚠️ اشتراك سنوي منتهي الصلاحية',
      'unpaidSub': '⏳ بانتظار سداد رسوم التفعيل',
      'daysRemaining': 'متبقي',
      'days': 'يوم',
      'expiresOn': 'ينتهي في',
      'superAdmin': 'المدير العام (Super Admin)',
      'approvedCaptain': 'كابتن معتمد',
      'customerUser': 'زبون',
      'editProfile': 'تعديل الملف الشخصي',
      'myVehicle': 'مركبتي',
      'whatsappSupport': 'واتساب ميسان',
      'activeTripNotification': 'رحلة نشطة',
      'passengerAcceptFare': 'موافق، ابدأ الرحلة',
      'passengerDeclineFare': 'رفض العرض',
      'driverProposesNewFare': 'الكابتن يقترح أجرة جديدة',
      'newFareProposal': 'الأجرة المقترحة',
    },
    'en': {
      // App General
      'appName': 'Maysan Captain',
      'appSlogan': 'Your trusted ride & delivery in Maysan Governorate',
      'maysanSpecialized': 'Specialized for Maysan Governorate & Districts',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search...',
      'filter': 'Filter',
      'all': 'All',
      'error': 'Error occurred',
      'success': 'Operation completed successfully',
      'retry': 'Retry',
      'noData': 'No data available',

      // Navigation & Sections
      'home': 'Home',
      'orders': 'Orders',
      'driverDashboard': 'Captain Dashboard',
      'adminDashboard': 'Admin Dashboard',
      'settings': 'Settings',
      'profile': 'Profile',

      // Auth
      'login': 'Sign In',
      'register': 'Create Account',
      'name': 'Full Name',
      'email': 'Email Address',
      'phone': 'Phone Number',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'loginIdentifierHint': 'Name, Email or Phone number',
      'loginButton': 'Sign In to App',
      'registerButton': 'Sign Up',
      'haveAccount': 'Already have an account? Sign In',
      'dontHaveAccount': "Don't have an account? Sign Up",
      'accountType': 'Account Type',
      'passengerUser': 'Passenger / Customer',
      'captainDriver': 'Captain / Driver',
      'invalidCredentials': 'Invalid credentials, please check and retry',
      'fillAllFields': 'Please fill all required fields',
      'passwordsDontMatch': 'Passwords do not match',

      // Map & Booking
      'rideService': 'Passenger Ride',
      'deliveryService': 'Package Delivery',
      'pickupLocation': 'Pickup Location',
      'dropoffLocation': 'Dropoff Location',
      'selectPickup': 'Select pickup point on map',
      'selectDropoff': 'Select destination point on map',
      'tapMapToSet': 'Tap map or drag pin to adjust location',
      'maysanLandmarks': 'Quick Maysan Districts & Landmarks',
      'estimatedFare': 'Estimated Fare',
      'iqd': 'IQD',
      'km': 'km',
      'distance': 'Estimated Distance',
      'bookNow': 'Book Ride Now',
      'requestDelivery': 'Request Delivery Now',
      'packageNotes': 'Order Notes or Package Details',
      'packageNotesHint': 'Write instructions or describe items...',
      'routeSummary': 'Route Summary in Maysan',

      // Vehicles
      'vehicleType': 'Vehicle Type',
      'vehicleModel': 'Vehicle Model & Year',
      'vehicleColor': 'Vehicle Color',
      'plateNumber': 'Plate Number',
      'registerVehicle': 'Register Vehicle',
      'myVehicles': 'My Vehicles',
      'salonTaxi': 'Sedan (Taxi)',
      'privateCar': 'Private Car',
      'motorcycle': 'Delivery Motorcycle',
      'tukTuk': 'Tuk-Tuk / Stotah',
      'pickupTruck': 'Pickup / Cargo Truck',
      'vipCar': 'VIP Luxury Car',

      // Statuses
      'statusPending': 'Pending',
      'statusAccepted': 'Accepted',
      'statusOnWay': 'Captain is on the way',
      'statusArrived': 'Captain arrived at pickup',
      'statusCompleted': 'Completed Successfully',
      'statusCancelled': 'Cancelled',

      // Driver Flow & Negotiation
      'incomingRequests': 'Available Requests',
      'proposedFare': 'Admin Base Fare',
      'customFare': 'Adjust Fare for this Request',
      'acceptWithFare': 'Accept Request with Fare',
      'rejectOrder': 'Decline',
      'callCustomer': 'Call Customer',
      'whatsappCustomer': 'WhatsApp Customer',
      'callDriver': 'Call Captain',
      'whatsappDriver': 'WhatsApp Captain',
      'updateStatus': 'Update Trip Status',
      'startTrip': 'Start Trip to Destination',
      'completeTrip': 'Complete & Collect Fare',
      'captainInfo': 'Captain Information',
      'customerInfo': 'Customer Information',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'rateTrip': 'Rate Trip & Captain',
      'submitRating': 'Submit Review',
      'writeComment': 'Write your feedback...',

      // Invoices
      'invoice': 'Trip Invoice',
      'exportPdf': 'Export PDF Invoice',
      'printInvoice': 'Print Invoice',
      'shareInvoice': 'Share Invoice',
      'invoiceNumber': 'Invoice #',
      'tripDate': 'Trip Date',
      'totalAmount': 'Total Amount',
      'tripBreakdown': 'Fare Breakdown & Route',

      // Admin Dashboard
      'adminTitle': 'Super Admin Dashboard',
      'totalUsers': 'Total Users',
      'totalDrivers': 'Total Captains',
      'totalRides': 'Total Rides',
      'totalDeliveries': 'Total Deliveries',
      'manageUsers': 'Manage Users',
      'manageDrivers': 'Manage Captains & Vehicles',
      'manageOrders': 'Manage Orders & Rides',
      'pricingSettings': 'Pricing Settings',
      'baseFare': 'Base Ride Fare (IQD)',
      'perKmRate': 'Per Kilometer Rate (IQD)',
      'deliveryBaseFare': 'Base Delivery Fare (IQD)',
      'updatePricing': 'Update Pricing Rules',

      // Settings
      'appSettings': 'Application Settings',
      'changeFont': 'Change App Font',
      'selectedFont': 'Active Font',
      'language': 'Language',
      'arabic': 'العربية (Iraq)',
      'english': 'English',
      'appearance': 'Appearance',
      'darkMode': 'Aurora Dark Mode',
      'lightMode': 'Aurora Light Mode',
      'developerInfo': 'Developer Information',
      'devCompany': 'Developed by: Maysan Tech',
      'devAuthor': 'Developer: Ali Saadoun Al-Mousawi',
      'contactDeveloper': 'Contact Developer',
      'visitWebsite': 'Visit Official Website',
      'logout': 'Sign Out',
      'logoutConfirm': 'Are you sure you want to sign out?',

      // Extra UI Keys
      'captainOnline': 'Captain Online (On Duty)',
      'captainOffline': 'Captain Offline (Break)',
      'availableOrders': 'Available Orders',
      'availableCount': 'Available',
      'acrossMaysan': 'Across Maysan Governorate',
      'openCaptainDashboard': 'Open Captain Dashboard',
      'hello': 'Hello, ',
      'tapToSetDestination': 'Tap to set destination & book ride',
      'tapToRevealOptions': 'Tap to view booking options',
      'waitingForPassenger': 'Waiting for Passenger Approval...',
      'proposedFareSent': 'Proposed fare sent to passenger. Live tracking will open automatically upon acceptance.',
      'proposedFareDeclined': 'The proposed fare was declined by passenger',
      'cancelProposal': 'Cancel Proposal',
      'passengerRide': 'Passenger Ride',
      'packageDelivery': 'Package Delivery',
      'noPendingOrders': 'No available requests currently in Maysan',
      'pullToRefresh': 'Pull down to refresh',
      'manageSubscription': 'Manage Subscription',
      'lifetimeSub': '👑 Lifetime Subscription',
      'annualSub': '📅 Annual Subscription',
      'expiredSub': '⚠️ Expired Annual Subscription',
      'unpaidSub': '⏳ Pending Activation Fee',
      'daysRemaining': 'Remaining',
      'days': 'days',
      'expiresOn': 'Expires on',
      'superAdmin': 'Super Admin',
      'approvedCaptain': 'Verified Captain',
      'customerUser': 'Customer',
      'editProfile': 'Edit Profile',
      'myVehicle': 'My Vehicle',
      'whatsappSupport': 'Maysan WhatsApp',
      'activeTripNotification': 'Active Trip',
      'passengerAcceptFare': 'Accept, Start Trip',
      'passengerDeclineFare': 'Decline Offer',
      'driverProposesNewFare': 'Captain proposed a new fare',
      'newFareProposal': 'Proposed Fare',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['ar']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
