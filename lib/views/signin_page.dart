import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:susu_micro/extensions/spacing.dart';
import 'package:susu_micro/models/staff.dart';
import 'package:susu_micro/providers/next_account_number.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/services/firebase_services.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/helpers.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/home_page.dart';
import 'package:susu_micro/widgets/textfomrfield.dart';
import 'package:susu_micro/providers/staff_provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  TextEditingController staffIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool isObscure = false;

  Future<void> signInStaff() async {
    final nextAccountNumberProvider = Provider.of<AccountNumberProvider>(context, listen: false);
    final staffId = staffIdController.text.trim();
    final password = passwordController.text.trim();
    logs.d("$staffId $password");
    if (staffId.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Staff ID and Password");
      return;
    }

    setState(() {
      _isLoading = true;
    });
      
    try {
      final response = await http
    .post(
      Uri.parse("https://susu-pro-backend.onrender.com/api/staff/sign-in"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"staff_id": staffId, "password": password}),
    )
    .timeout(const Duration(seconds: 50));
    final responseJson = jsonDecode(response.body);
    
      logs.d("Response: ${response.body}");
      if (response.statusCode == 200) {
        final staffData = responseJson["data"]; 
          Provider.of<StaffProvider>(context, listen: false).setStaff(
    id: staffData["id"],
    staffId: staffData["staff_id"],
    fullName: staffData["full_name"],
    email: staffData["email"],
    phone: staffData["phone"],
    role: staffData["role"],
    companyId: staffData["company_id"],
    token: responseJson["token"] ?? "",
    companyName: staffData["company_name"] ?? "",
    );
    final loggedInStaff = Staff(id: staffData['id'], name: staffData['full_name'], email: staffData['email'], role: staffData['role']);
    await saveStaff(staffData["company_id"], loggedInStaff);
    logs.d('Refreshing next account number for staff ID: ${staffData["id"]}');
          nextAccountNumberProvider.refreshAccountNumber(staffData["id"]);
          
        Fluttertoast.showToast(msg: "Login successful");

        Navigator.of(context).pushReplacement(
          FadeRoute(page: const HomePage()),
        );
      } else {
        final error = jsonDecode(response.body);
        Fluttertoast.showToast(msg: error["message"] ?? "Login failed");
      }
    } catch (e) {
      logs.d(e);
      Fluttertoast.showToast(msg: "Error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyTexts().titleText("Susu~Pro"),
            Image(
              image: AssetImage(AppAssets.appIcon),
              width: 130,
              height: 130,
            ),
            40.0.vSpace,
            MyTextFields().buildTextField(
              "Staff ID eg. ABC001",
              staffIdController,
              context,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your Staff ID";
                }
                return null;
              },
            ),
            10.0.vSpace,
            SizedBox(
      width: Screen.width(context) * 0.85,
      child: TextFormField(
        validator: (validator) {
          if (validator == null || validator.isEmpty) {
            return "Please enter your password";
          }
          return null;
        },
        obscureText: isObscure,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors().primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors().primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: "Password",
          hintStyle:
              TextStyle(fontFamily: 'Poppins', color: Colors.grey),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors().primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: InkWell(
            onTap: () {
              setState(() {
                isObscure = !isObscure;
              });;
            },
            child: Icon(
              isObscure ? Icons.visibility : Icons.visibility_off,
              color: AppColors().lightGrey,
            ),
          ),
        ),
        controller: passwordController,
      ),
    ),
            20.0.vSpace,
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 100.0),
             child: ElevatedButton(
                      onPressed: signInStaff,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors().primaryColor,
                        minimumSize: Size(Screen.width(context) * 0.4, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isLoading ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator()) : SizedBox(),
                            _isLoading ? SizedBox(width: 10,) : SizedBox(),
                          MyTexts().regularText(
                            _isLoading ? "Signing In..." : "Sign In",
                            textColor: AppColors().whiteColor,
                          ),
                          ],
                      ),
                    ),
           ),
          ],
        ),
      ),
    );
  }
}
