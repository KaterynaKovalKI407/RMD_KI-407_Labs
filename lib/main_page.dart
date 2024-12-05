import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rmd_koval_ki407_lab2/user_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/user_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:rmd_koval_ki407_lab2/uv_index_widget.dart';
//import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends StatefulWidget {
  final int patientId;
  const MainPage({Key? key, required this.patientId}) : super(key: key);
  

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isConnectedToInternet = false;
  StreamSubscription? _internetConnectionStreamSubscription;
  String? userEmail;
  List<Map<String, dynamic>> specialities = [];
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> dates = [];
  List<Map<String, dynamic>> times = [];
  int? selectedSpecialityId;
  String? selectedSpeciality;
  int? selectedDoctorId;
  Map<String, dynamic>? selectedDoctor; 
  Map<String, dynamic>? selectedDate;
  Map<String, dynamic>? selectedTime;


  @override
  void initState() {
    super.initState();
    print('Received Patient ID in MainPage: ${widget.patientId}');
    _loadUserEmail();
    _fetchSpecialities();
    

    // Initial internet connection check
    InternetConnectionCheckerPlus().hasConnection.then((status) {
      setState(() {
        isConnectedToInternet = status;
        print("Initial internet connection status: $isConnectedToInternet");
      });
    });

    // Stream for ongoing status updates
    _internetConnectionStreamSubscription =
        InternetConnectionCheckerPlus().onStatusChange.listen((event) {
      print("Connection status changed: $event");
      switch (event) {
        case InternetConnectionStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetConnectionStatus.disconnected:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
        default:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
      }
    });

  }
  @override
  void dispose() {
    _internetConnectionStreamSubscription?.cancel();
    super.dispose();
  }
  // Додаємо асинхронну функцію для отримання електронної пошти користувача
  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userPreferences = UserPreferences(prefs);
    String? email = userPreferences.getUserEmail();
    setState(() {
      userEmail = email;
    });
  }
// Метод для завантаження спеціальностей з сервера
Future<void> _fetchSpecialities() async {
    final response = await Supabase.instance.client
        .from('specialities')
        .select()
        .execute();

    if (response.error == null && response.data != null) {
      setState(() {
        specialities = (response.data as List<dynamic>)
            .map((item) => {
                  'id': item['id'],
                  'name': item['name'],
                })
            .toList();
      });
      print("Specialities loaded: $specialities");
    } else {
      print("Failed to load specialities: ${response.error?.message}");
    }
  }
  // Метод для завантаження лікарів залежно від id спеціальності
  Future<void> _fetchDoctorsBySpeciality(int specialityId) async {
    final response = await Supabase.instance.client
        .from('doctors')
        .select()
        .eq('speciality_id', specialityId)
        .execute();

    if (response.error == null && response.data != null) {
      setState(() {
        doctors = (response.data as List<dynamic>)
            .map((item) => {
                  'id': item['id'],
                  'name': item['name'],
                })
            .toList();
        selectedDoctor = null;
        dates = []; 
        selectedDate = null;
        selectedDoctorId = null;
      });
      print("Doctors loaded for speciality $specialityId: $doctors");
    } else {
      print("Failed to load doctors: ${response.error?.message}");
    }
  }

// Метод для завантаження дат залежно від id лікаря
 Future<void> _fetchDatesByDoctors(int doctorId) async {
  final response = await Supabase.instance.client
      .from('available_times')
      .select()
      .eq('doctor_id', doctorId)
      .execute();

  if (response.error == null && response.data != null) {
    setState(() {
      final uniqueDates = (response.data as List<dynamic>)
          .map((item) => item['available_date'])
          .toSet() 
          .map((date) => {
                'available_date': date,
              })
          .toList();
      dates = uniqueDates;
      selectedDate = null;
    });
    print("Available unique dates for doctor $doctorId: $dates");
  } else {
    print("Failed to load dates: ${response.error?.message}");
  }
}

// Метод для завантаження годин залежно від дати
Future<void> _fetchTimesByDates(int doctorId, String availableDate) async {
  final response = await Supabase.instance.client
      .from('available_times')
      .select()
      .eq('doctor_id', doctorId)
      .eq('available_date', availableDate)
      .eq('is_available', true)
      .execute();

  if (response.error == null && response.data != null) {
    setState(() {
      times = (response.data as List<dynamic>)
          .map((item) => {
                'id': item['id'],
                'available_time': item['available_time'],
              })
          .toList();

      // Сортуємо години за зростанням
      times.sort((a, b) => (a['available_time'] as String).compareTo(b['available_time'] as String));
      
      selectedTime = null;
    });
    print("Available times for doctor $doctorId on date $availableDate: $times");
  } else {
    print("Failed to load times: ${response.error?.message}");
  }
}

void resetSelections() {
    setState(() {
      selectedSpeciality = null;
      selectedSpecialityId = null;
      selectedDoctor = null;
      selectedDoctorId = null;
      selectedDate = null;
      selectedTime = null;
      doctors = [];
      dates = [];
      times = [];
    });
  }

  Future<void> _makeAppointment(int? patientId, int doctorId, String date, String time) async {
  if (patientId == null) {
    print("Patient ID is null.");
    return;
  }

  final response = await Supabase.instance.client
      .from('available_times')
      .update({
        'patient_id': patientId,
        'is_available': false,
      })
      .eq('doctor_id', doctorId)
      .eq('available_date', date)
      .eq('available_time', time)
      .select('id') // Отримуємо id новоствореного запису
      .single()
      .execute();

  if (response.error == null) {
    resetSelections();

    final appointmentId = response.data['id'] as int;
    print("Appointment created with ID: $appointmentId");

    // Передаємо appointmentId на UserProfilePage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          patientId: widget.patientId,
          appointmentId: appointmentId,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment successfully created!'),
        duration: Duration(seconds: 3),
      ),
    );
  } else {
    print("Failed to create appointment: ${response.error?.message}");
  }
}

void _validateAndMakeAppointment() {
    if (!isConnectedToInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect to the internet to make an appointment.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (selectedSpeciality == null || selectedDoctor == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor speciality, doctor, date, and time.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      _makeAppointment(widget.patientId, selectedDoctorId!, selectedDate!['available_date'] as String, selectedTime!['available_time'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        actions: [
          UVIndexWidget(), 
          const SizedBox(width: 16),
          ConnectionStatusWidget(isConnected: isConnectedToInternet),
          const SizedBox(width: 16),
          const MusicContextMenu(), 
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            DropdownButton<String>(
              hint: const Text("Select Speciality"),
              value: selectedSpeciality,
              items: specialities.map((speciality) {
                return DropdownMenuItem<String>(
                  value: speciality['name'] as String,
                  child: Text(speciality['name'] as String),
                  onTap: () {
                    setState(() {
                      selectedSpecialityId = speciality['id'] as int;
                      selectedDoctor = null;
                      dates = []; 
                      times = [];
                      selectedDate = null;
                      selectedTime = null;
                    });
                  },
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSpeciality = newValue;
                  if (selectedSpecialityId != null && selectedSpecialityId! > 0) {
                    _fetchDoctorsBySpeciality(selectedSpecialityId!);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select Doctor"),
              value: selectedDoctor,
              items: doctors.map((doctor) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: doctor,
                  child: Text(doctor['name'] as String),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  selectedDoctor = newValue;
                  selectedDoctorId = selectedDoctor?['id'] as int;
                  dates = []; 
                  times = []; 
                  selectedDate = null;
                  selectedTime = null;
                  if (selectedDoctor != null) {
                    _fetchDatesByDoctors(selectedDoctorId!);
                  }
                });
                print("Selected doctor: ${selectedDoctor?['name']} with ID: ${selectedDoctor?['id']}");
              },
            ),
            const SizedBox(height: 16),
            DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select Date"),
              value: selectedDate,
              items: dates.map((date) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: date,
                  child: Text(date['available_date'] as String),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  selectedDate = newValue;
                  selectedTime = null;
                  times = []; 
                  if (selectedDate != null) {
                    _fetchTimesByDates(selectedDoctorId!, selectedDate!['available_date'] as String);
                  }
                });
                print("Selected date: ${selectedDate?['available_date']}");
              },
            ),
            const SizedBox(height: 16),
            DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select Time"),
              value: selectedTime,
              items: times.map((time) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: time,
                  child: Text(time['available_time'] as String),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  selectedTime = newValue;
                });
                print("Selected time: ${selectedTime?['available_time']}");
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _validateAndMakeAppointment, 
              child: const Text('Make an Appointment'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfilePage(
                    patientId: widget.patientId)),
                );
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
            
class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusWidget({required this.isConnected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      isConnected ? Icons.wifi_outlined : Icons.wifi_off_outlined,
      color: isConnected ? Colors.green : Colors.red,
      size: 40, 
    );
  }
}
