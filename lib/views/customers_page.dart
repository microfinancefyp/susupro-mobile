import 'package:flutter/material.dart';
import 'package:susu_micro/route_transitions/route_transition_fade.dart';
import 'package:susu_micro/utils/appAssets.dart';
import 'package:susu_micro/utils/colors.dart';
import 'package:susu_micro/utils/screen_measurement.dart';
import 'package:susu_micro/utils/text.dart';
import 'package:susu_micro/views/customer_detail.dart';
import 'package:susu_micro/views/staking_page.dart';
import 'package:susu_micro/widgets/appBar.dart';
import 'package:susu_micro/widgets/customer_widget.dart';
import 'package:susu_micro/widgets/textfomrfield.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _customers = [
    {'name': 'John Doe', 'location': 'Accra', 'dailyRate': 'GHC 10'},
    {'name': 'Jane Smith', 'location': 'Kumasi', 'dailyRate': 'GHC 15'},
    {'name': 'Michael Brown', 'location': 'Cape Coast', 'dailyRate': 'GHC 12'},
    {'name': 'Sarah Johnson', 'location': 'Accra', 'dailyRate': 'GHC 20'},
    {'name': 'Samuel Tetteh', 'location': 'Tema', 'dailyRate': 'GHC 18'},
    {'name': 'Augustine Love', 'location': 'Agona', 'dailyRate': 'GHC 5'}
  ];

  final List<String> _locations = [
    'All',
    'Accra',
    'Kumasi',
    'Cape Coast',
    'Tema',
    'Agona'
  ];

  String _selectedLocation = 'All';
  List<Map<String, String>> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = _customers;
  }

  void _filterCustomers(String location) {
    setState(() {
      _selectedLocation = location;
      if (location == 'All') {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers
            .where((customer) => customer['location'] == location)
            .toList();
      }
    });
  }

  Future<void> _refresh() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().whiteColor,
      appBar: MyAppBar.buildAppBar(context, "Customers"),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: MyTextFields().buildTextField(
                  "Search for a customer",
                  _searchController,
                  context,
                  borderColor: AppColors().lightGrey,
                  formWidth: Screen.width(context) * 0.97,
                  icon: Icons.search,
                  textColor: Colors.grey,
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  final isSelected = _selectedLocation == location;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80)),
                      label: MyTexts().regularText(location),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _filterCustomers(location);
                        }
                      },
                      selectedColor: AppColors().primaryColor,
                      backgroundColor: AppColors().whiteColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _filteredCustomers[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(FadeRoute(
                          page: StakingPage(
                        customerName: "${customer['name']}",
                      )));
                    },
                    child: CustomerWidget(
                        customerName: "${customer['name']}",
                        customerLocatoin: "${customer['location']}",
                        customerDailyRate: "${customer['dailyRate']}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
