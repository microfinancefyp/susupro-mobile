class CustomerModel {
  String? fullName;
  String? location;
  String? phoneNumber;
  String? password;
  String? profilePic;
  String? uid;
  String? createdAt;
  String? updatedAt;
  String? status;
  String? role;
  String? address;
  String? city;
  String? gender;
  String? latitude;
  String? longitude;
  String? profileImageType;
  String? profileImageUrl;
  String? dailyRate;
  String? idCard;
  String? dob;
  String? email;
  String? nextOfKin;
  String? dateOfRegistration;
  String? account_number;
  String? momo_number;
  double? totalBalance;


  CustomerModel({
    this.fullName,
    this.location,
    this.phoneNumber,
    this.password,
    this.profilePic,
    this.uid,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.role,
    this.address,
    this.city,
    this.gender,
    this.latitude,
    this.dailyRate,
    this.idCard,
    this.dob,
    this.email,
    this.nextOfKin,
    this.dateOfRegistration,
    this.account_number,
    this.momo_number,
    this.totalBalance,
  });

  CustomerModel.fromJson(Map<String, dynamic> json) {
    fullName = json['name'];
    location = json['location'];
    phoneNumber = json['phone_number'];
    password = json['password'];
    profilePic = json['profilePic'];
    uid = json['id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    status = json['status'];
    dailyRate = json['daily_rate'];
    idCard = json['id_card'];
    dob = json['date_of_birth'];
    email = json['email'];
    gender = json['gender'];
    nextOfKin = json['next_of_kin'];
    dateOfRegistration = json['date_of_registration'];
    account_number = json['account_number'];
    momo_number= json['momo_number'];
    totalBalance = double.tryParse(json['totalBalance']?.toString() ?? '0') ?? 0.0;
    }

    CustomerModel copyWith({
  String? fullName,
  String? location,
  String? phoneNumber,
  String? password,
  String? profilePic,
  String? uid,
  String? createdAt,
  String? updatedAt,
  String? status,
  String? dailyRate,
  String? idCard,
  String? dob,
  String? email,
  String? gender,
  String? nextOfKin,
  String? dateOfRegistration,
  String? accountNumber,
  String? momoNumber,
  double? totalBalance,
}) {
  return CustomerModel(
    fullName: fullName ?? this.fullName,
    location: location ?? this.location,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    password: password ?? this.password,
    profilePic: profilePic ?? this.profilePic,
    uid: uid ?? this.uid,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
    dailyRate: dailyRate ?? this.dailyRate,
    idCard: idCard ?? this.idCard,
    dob: dob ?? this.dob,
    email: email ?? this.email,
    gender: gender ?? this.gender,
    nextOfKin: nextOfKin ?? this.nextOfKin,
    dateOfRegistration: dateOfRegistration ?? this.dateOfRegistration,
    account_number: accountNumber ?? account_number,
    momo_number: momoNumber ?? momo_number,
    totalBalance: totalBalance ?? this.totalBalance,
  );
}

}
