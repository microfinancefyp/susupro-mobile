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
  String? country;
  String? latitude;
  String? longitude;
  String? profileImageType;
  String? profileImageUrl;

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
    this.country,
    this.latitude,
  });

  CustomerModel.fromJson(Map<String, dynamic> json) {
    fullName = json['fullName'];
    location = json['location'];
    phoneNumber = json['phoneNumber'];
    password = json['password'];
    profilePic = json['profilePic'];
    uid = json['uid'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    status = json['status'];
  }
}
