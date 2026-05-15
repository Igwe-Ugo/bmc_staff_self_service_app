import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    String aboutSelfHeading = "BMC staff self-service";
    String aboutWhat = "What You Can Do";
    String aboutWhy = "Why We Built This App";
    String aboutCommitment = "Our Commitment";
    String aboutSecurity = "Security & Privacy";
    String aboutSupport = "Support";
    String aboutVersion = "Version Information";
    String aboutMotivate = "Empowering Healthcare Staff Through Smarter Workforce Coordination";

    // notes
    String noteSelfService = "The BMC Staff self-service App is the official mobile workforce management platform for Bethany Medical Center, designed to support healthcare professionals with fast, secure, and convenient access to essential staff services. Built for the demands of modern healthcare environments, the app helps staff stay connected to their schedules, availability, leave requests, and HR information anytime and anywhere.";
    String noteWhy = "At Bethany Medical Center, we understand that healthcare professionals work in fast-paced and demanding environments where time, clarity, and accessibility are essential. The BMC Staff App was created to simplify workforce coordination, reduce administrative stress, and improve communication between staff and management through a modern mobile experience.";
    String noteCommitment = "We are committed to providing a secure, reliable, and user-friendly platform that supports operational efficiency while maintaining the confidentiality and integrity of staff information.";
    String noteSecurity = "The BMC Staff App uses secure authentication and protected data systems to help ensure that sensitive staff records remain confidential and accessible only to authorized users.";
    String noteVersion = "Application Name: BMC Staff  Self-Service App\nOrganization: Bethany Medical Center\nVersion: 1.0.0\nLast Updated: May 2026";
    String noteSupport = "For technical assistance, account-related support, or workforce management inquiries, please contact the ICT department or your assigned hospital administrator at Bethany Medical Center.";
    String noteMotivate = "“Whatever you do, work at it with all your heart, as working for the Lord.”\n— Colossians 3:23";

    // subnote
    String subNoteAvailability = "Manage Availability";
    String subNoteRota = "Access your Rota";
    String subNoteLeave = "Request Leave";
    String subNoteProfile = "Manage your Profile";

    //sub-subnotes
    String noteAvailabilityWhat = "Quickly update your availability during open scheduling periods and stay aligned with workforce planning.";
    String noteRota = "View assigned shifts, locations, and work schedules in real time with clear and organized shift management.";
    String noteLeave = "Submit leave requests, track approvals, and manage leave history with a transparent and streamlined process.";
    String noteProfile = "Securely access personal records, professional documents, placements, and staff information in one place.";

    final Map<String, String> aboutApp = {
      subNoteAvailability: noteAvailabilityWhat,
      subNoteRota: noteRota,
      subNoteLeave: noteLeave,
      subNoteProfile: noteProfile,
    };

    final whatNotes = aboutApp.entries.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              GoRouter.of(context).pop();
            },
            icon: const Icon(
              Iconsax.arrow_left,
              size: 17,
            )),
        title: Text(
          "About App",
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 30),
          child: Column(
            children: [
              _SectionTitle(title: aboutSelfHeading, note: noteSelfService),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    aboutWhat,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        fontFamily: 'Lexend'
                    )
                ),
              ),
              const SizedBox(height: 16,),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).hoverColor,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: whatNotes.length,
                  itemBuilder: (context, index) {
                    final note = whatNotes[index];
                    return _SectionWhat(subtitle: note.key, note: note.value);
                  }
                ),
              ),
              const SizedBox(height: 24,),
              _SectionTitle(title: aboutWhy, note: noteWhy),
              _SectionTitle(title: aboutCommitment, note: noteCommitment),
              _SectionTitle(title: aboutSecurity, note: noteSecurity,),
              _SectionTitle(title: aboutVersion, note: noteVersion),
              _SectionTitle(title: aboutSupport, note: noteSupport),
              _SectionTitle(title: aboutMotivate, note: noteMotivate),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String note;

  const _SectionTitle({required this.title, required this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'Lexend'
            )
          ),
        const SizedBox(height: 16,),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).hoverColor,
          ),
          child: Text(
              note,
              style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                  fontFamily: 'Lexend'
              )
          ),
        ),
        const SizedBox(height: 24,)
      ],
    );
  }
}

class _SectionWhat extends StatelessWidget {
  final String subtitle;
  final String note;

  const _SectionWhat({required this.subtitle, required this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                subtitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Lexend'
                )
            ),
            const SizedBox(height: 10,),
            Text(
                note,
                style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                    fontFamily: 'Lexend'
                )
            ),
            const SizedBox(height: 16,)
          ],
        );
  }
}
