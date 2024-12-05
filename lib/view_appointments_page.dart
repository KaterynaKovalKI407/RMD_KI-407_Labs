import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewAppointmentsPage extends StatefulWidget {
  final int? patientId;
  final int? appointmentId; 
 const ViewAppointmentsPage({Key? key, required this.patientId, this.appointmentId}) : super(key: key);
  

  @override
  _ViewAppointmentsPageState createState() => _ViewAppointmentsPageState();
}

class _ViewAppointmentsPageState extends State<ViewAppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
  // Виконуємо запит із JOIN для отримання даних із пов'язаних таблиць
  final response = await Supabase.instance.client
      .from('available_times')
      .select('id, available_date, available_time, doctor:doctors(name, speciality:specialities(name))')
      .eq('patient_id', widget.patientId)
      .execute();

  if (response.error == null) {
    final data = response.data as List;
    
    // Створюємо Set для відслідковування унікальних комбінацій дати та часу
    final uniqueAppointments = <String>{};

    setState(() {
      appointments = data
          .where((appointment) {
            final date = appointment['available_date'];
            final time = appointment['available_time'];
            final dateTimeKey = '$date $time';
            
            // Якщо комбінація дати та часу вже існує, пропускаємо її
            if (uniqueAppointments.contains(dateTimeKey)) {
              return false;
            } else {
              uniqueAppointments.add(dateTimeKey);
              return true;
            }
          })
          .map((appointment) => Map<String, dynamic>.from(appointment as Map<String, dynamic>))
          .toList();

      // Сортуємо список за датою
      appointments.sort((a, b) {
        final dateA = DateTime.parse(a['available_date']as String);
        final dateB = DateTime.parse(b['available_date']as String);
        return dateA.compareTo(dateB);
      });
    });
  } else {
    print("Failed to fetch appointments: ${response.error?.message}");
  }
}

  Future<void> _cancelAppointment(int appointmentId) async {
  // Updating the 'available_times' record to make the slot available by setting 'is_available' to true
  // and clearing 'patient_id'
  final response = await Supabase.instance.client
      .from('available_times')
      .update({
        'is_available': true,
        'patient_id': null, // Clearing the 'patient_id' field
      })
      .eq('id', appointmentId)
      .eq('patient_id', widget.patientId) // Ensuring the correct patient is canceling the appointment
      .execute();

  if (response.error == null) {
    setState(() {
      // Removing the canceled appointment from the local 'appointments' list
      appointments.removeWhere((appointment) => appointment['id'] == appointmentId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment canceled successfully')),
    );
  } else {
    print("Failed to cancel appointment: ${response.error?.message}");
  }
}
  void _showCancelDialog(int appointmentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(appointmentId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
      ),
      body: appointments.isEmpty
          ? const Center(child: Text("No appointments found."))
          : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final doctorName = appointment['doctor']['name'];
                final specialityName = appointment['doctor']['speciality']['name'];
                final availableDate = appointment['available_date'];
                final availableTime = appointment['available_time'];
                
                return ListTile(
                  title: Text(
                    '$doctorName - $specialityName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Date: $availableDate\nTime: $availableTime',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _showCancelDialog(appointment['id'] as int),
                  ),
                );
              },
            ),
    );
  }
}