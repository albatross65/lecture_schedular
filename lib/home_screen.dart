import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';  // Lottie animations
import 'add_edit_schedule_screen.dart';
import 'auth_screen.dart';
import 'main.dart';  // Notification plugin
import 'package:timezone/data/latest.dart' as tz;  // Import timezone library
import 'package:timezone/timezone.dart' as tz;     // Import timezone

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> motivationalImages = [
    'assets/images/quote1.jpg',
    'assets/images/quote2.jpg',
    'assets/images/quote3.jpg',
    'assets/images/quote4.jpg',
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate a delay for loading (Lottie animation during load)
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _scheduleNotification(String title, DateTime scheduledTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'lecture_channel',
      'Lecture Reminder',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      fullScreenIntent: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Lecture Reminder',
      '$title is starting soon!',
      tz.TZDateTime.from(scheduledTime, tz.local),  // Convert DateTime to TZDateTime
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,  // Add this line
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Schedules', style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.signOutAlt),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AuthScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Motivational quotes carousel
          CarouselSlider(
            items: motivationalImages.map((imgPath) {
              return SvgPicture.asset(imgPath, fit: BoxFit.cover);
            }).toList(),
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
          ),

          // Lottie animation during loading
          _isLoading
              ? Expanded(
            child: Center(
              child: Lottie.asset('assets/lottie/loading.json'),
            ),
          )
              : Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('schedules').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListView.builder(
                      itemCount: 6,
                      itemBuilder: (context, index) => Container(
                        height: 100,
                        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  );
                }

                var schedules = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    var schedule = schedules[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AddEditScheduleScreen(
                            docId: schedule.id,
                            currentSubject: schedule['subject'],
                            currentDate: schedule['date'],
                            currentTime: schedule['time'],
                          ),
                        ));
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(schedule['subject'],
                              style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold)),
                          subtitle:
                          Text('${schedule['date']} - ${schedule['time']}'),
                          trailing: IconButton(
                            icon: FaIcon(FontAwesomeIcons.trash),
                            onPressed: () async {
                              await _firestore
                                  .collection('schedules')
                                  .doc(schedule.id)
                                  .delete();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
