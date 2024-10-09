import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = FlutterSecureStorage();
  String? selectedEmployee;
  List<Map<String, dynamic>> employees = [];
  String? selectedEmployeeId;
  String? entryTime;
  String? exitTime;
  final supabase = Supabase.instance.client;

  // Fetch employee data from Supabase
  Future<void> fetchEmployeeData() async {
    final response = await supabase.from('employees').select('*');

    if (response != null) {
      setState(() {
        employees = List<Map<String, dynamic>>.from(response as List); // Populate the employees list
      });
    } else {
      print('Error fetching employee data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEmployeeData(); // Fetch employee data when screen loads
  }

  Future<void> _logout() async {
    await storage.deleteAll(); // Clear all data from secure storage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> markEntryTime(String employeeId) async {
    try {
      // Get the last log of the employee sorted by entry_time, also sort by null first
      final logsResponse = await supabase
          .from('work_logs')
          .select('employee_id, entry_date_time, exit_date_time')
          .eq('employee_id', employeeId)
          .order('entry_date_time', ascending: false)
          .order('exit_date_time', nullsFirst: true)
          .limit(1);

      // Check if the last log is an entry log or if logsResponse is empty
      if (logsResponse.isEmpty || logsResponse[0]['exit_date_time'] != null) {
        DateTime now = DateTime.now();
        //DateTime roundedDateTime = getRoundedDateTimeTo30Mins(now);
        String roundedDateTimeISO = now.toUtc().toIso8601String(); // UTC format

        // print('employee_id: $employeeId');
        // print('entry_date_time: $roundedDateTimeISO');

        // Insert new log into work_logs
        final insertResponse = await supabase.from('work_logs').insert([
          {
            'employee_id': employeeId,
            'entry_date_time': roundedDateTimeISO,
          },
        ]);

        // update the state to show the latest entry time
        setState(() {
          fetchLatestLog(employeeId);
        });

        // Show success message after marking entry time
        showDialog(context: context, builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Success',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: const Text(
              'Entry time marked successfully.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        });

        // print('Entry-Date-Time: $roundedDateTimeISO');
        // print("Entry time marked successfully");

      } else {
        // Show error dialog if previous exit time not marked
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: const Text(
                'Exit time not marked.\nPlease mark exit time first.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> markExit(String employeeId) async {
    try {
      // Get the last log of the employee sorted by entry_time in descending order
      final logsResponse = await supabase
          .from('work_logs')
          .select('employee_id, entry_date_time, exit_date_time')
          .eq('employee_id', employeeId)
          .order('entry_date_time', ascending: false)
          .order('exit_date_time', nullsFirst: true)
          .limit(1) ;

      // Check if the last log is an entry log
      if (logsResponse[0]['exit_date_time'] == null && logsResponse[0]['entry_date_time'] != null) {
        // Get current time and round it to the nearest 30 minutes
        DateTime now = DateTime.now();
        // DateTime roundedDateTime = getRoundedDateTimeTo30Mins(now);
        String roundedDateTimeISO = now.toUtc().toIso8601String(); // UTC format

        // print('employee_id--------------------: $employeeId');
        // print('exit_date_time: $roundedDateTimeISO');

        // Update the last log with exit time
        final updateResponse = await supabase
            .from('work_logs')
            .update({'exit_date_time': roundedDateTimeISO})
            .eq('employee_id', employeeId)
            .eq('entry_date_time', logsResponse[0]['entry_date_time']);

        // Update the state to show the latest exit time
        setState(() {
          // dates in UTC format
          fetchLatestLog(employeeId);
        });

        // show some success message after marking exit time, show alert dialog
        showDialog(context: context, builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Success',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: const Text(
              'Exit time marked successfully.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        });

        // print("Exit time marked successfully");
      } else {
        // Previous exit time already marked, show error message using a dialog
        // print('Previous exit time already marked');
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners for smooth UI
              ),
              title: const Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Minimalist text color
                ),
              ),
              content: const Text(
                'Previous exit time already marked.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54, // Subtle content color
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 12, bottom: 8), // Clean padding for actions
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

      }
    } catch (e) {
      print('Error: $e');
    }
  }


// Function to round the DateTime to the nearest 30 minutes
  DateTime getRoundedDateTimeTo30Mins(DateTime date) {
    final int coeff = 1000 * 60 * 30; // 30 minutes in milliseconds
    return DateTime.fromMillisecondsSinceEpoch(
      (date.millisecondsSinceEpoch ~/ coeff) * coeff,
    );
  }

  Future<void> fetchLatestLog(String employeeId) async {
    final logsResponse = await supabase
        .from('work_logs')
        .select('entry_date_time, exit_date_time')
        .eq('employee_id', employeeId)
        .order('entry_date_time', ascending: false)
        .order('exit_date_time', nullsFirst: true)
        .limit(1);

    // print('Logs------: $logsResponse');

    // Parse ISO dates to DateTime objects in
    DateTime entryDateTimeUtc = DateTime.parse(logsResponse[0]['entry_date_time']+'Z');
    DateTime? exitDateTimeUtc = logsResponse[0]['exit_date_time'] != null
        ? DateTime.parse(logsResponse[0]['exit_date_time']+'Z')
        : null;

    // // Debugging: Print the DateTime objects
    // print('Entry DateTime UTC: $entryDateTimeUtc'); // Print UTC DateTime
    // //print('Entry DateTime Local: $entryDateTimeLocal'); // Print Local DateTime
    // print('Current Local Time: ${DateTime.now()}');



    setState(() {
      entryTime = entryDateTimeUtc != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(entryDateTimeUtc.toLocal())
          : null;
      exitTime = exitDateTimeUtc != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(exitDateTimeUtc.toLocal())
          : null;
    });

    // print('Entry Time: $entryTime');
    // print('Exit Time: $exitTime');
  }




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Time Keeper', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Employee',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              // Dropdown to select employee if employees list is populated
              if (employees.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.black), // Default border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.black, width: 2), // Black border when selected
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  hint: const Text('Select Employee'),
                  value: selectedEmployeeId,
                  items: employees.map((employee) {
                    String displayName = '${employee['name']} (${employee['identification_number']})';
                    return DropdownMenuItem<String>(
                      value: employee['id'].toString(),
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedEmployeeId = newValue;
                    });
                    fetchLatestLog(selectedEmployeeId!);
                  },
                ),
              const SizedBox(height: 20),
              // Show buttons only if employee is selected
              if (selectedEmployeeId != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              markEntryTime(selectedEmployeeId!);
                            },
                            child: const Text(
                              'Mark Entry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              backgroundColor: Colors.black54, // Sleek teal color for entry button

                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Space between buttons
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              markExit(selectedEmployeeId!);
                            },
                            child: const Text(
                              'Mark Exit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              const SizedBox(height: 40),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selectedEmployeeId != null)
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Image(image: AssetImage('assets/entry.png'), width: 100, height: 100),
                                        const SizedBox(width: 10),
                                        Column(
                                          children: [
                                            const Text(
                                              'Entry Time',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entryTime != null
                                                      ? DateFormat('HH:mm').format(DateTime.parse(entryTime!))
                                                      : 'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const SizedBox(height: 4), // Small space between time and date
                                                Text(
                                                  entryTime != null
                                                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(entryTime!))
                                                      : 'N/A', // Show date
                                                  style: const TextStyle(
                                                    fontSize: 16, // Smaller font size for date
                                                    color: Colors.grey, // Optional: lighter color for date
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 6,),

                            // Card for Exit Time
                            Card(
                              margin: const EdgeInsets.only(bottom: 16.0), // Margin below the card
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                side: const BorderSide(
                                  color: Colors.black, // Border color
                                  width: 1.5, // Border width
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0), // Padding inside the card
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        const SizedBox(width: 22),
                                        Column(
                                          children: [
                                            const Text(
                                              'Exit Time',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black // Customize color
                                              ),
                                            ),
                                            const SizedBox(height: 4), // Space between title and time
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                                              children: [
                                                Text(
                                                  exitTime != null
                                                      ? DateFormat('HH:mm').format(DateTime.parse(exitTime!))
                                                      : 'N/A', // Show only time
                                                  style: const TextStyle(
                                                    fontSize: 36, // Larger font size for time
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const SizedBox(height: 4), // Small space between time and date
                                                Text(
                                                  exitTime != null
                                                      ? DateFormat('yyyy-MM-dd').format(DateTime.parse(exitTime!))
                                                      : 'N/A', // Show date
                                                  style: const TextStyle(
                                                    fontSize: 16, // Smaller font size for date
                                                    color: Colors.grey, // Optional: lighter color for date
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 50),
                                        Image(image: AssetImage('assets/exit.png'), width: 100, height: 100),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                  ],
                ),
              ),
                  ],
                ),
              ),

      ),
    );
  }
}
