import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAgriBaseScreen extends StatelessWidget {
  const AboutAgriBaseScreen({super.key});

  static final Uri _privacyPolicyUri = Uri.parse(
    'https://chinatsvi.github.io/farmer-community-privacy-policy/',
  );

  static final Uri _termsConditionsUri = Uri.parse(
    'https://chinatsvi.github.io/farmer-community-terms/',
  );

  static final Uri _contactUsUri = Uri.parse(
    'https://chinatsvi.github.io/farmer-community-contact-us/',
  );

  static final Uri _helpFaqUri = Uri.parse(
    'https://chinatsvi.github.io/farmer-community-Help-FAQ/',
  );

  static final Uri _farmersCommunityUri = Uri.parse(
    'https://chinatsvi.github.io/',
  );

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    if (await canLaunchUrl(_privacyPolicyUri)) {
      await launchUrl(_privacyPolicyUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Privacy Policy')),
      );
    }
  }

  Future<void> _openTermsConditions(BuildContext context) async {
    if (await canLaunchUrl(_termsConditionsUri)) {
      await launchUrl(_termsConditionsUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Terms & Conditions')),
      );
    }
  }

  Future<void> _openContactUs(BuildContext context) async {
    if (await canLaunchUrl(_contactUsUri)) {
      await launchUrl(_contactUsUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Contact Us')),
      );
    }
  }

  Future<void> _openHelpFaq(BuildContext context) async {
    if (await canLaunchUrl(_helpFaqUri)) {
      await launchUrl(_helpFaqUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Help & FAQ')),
      );
    }
  }

  Future<void> _openFarmersCommunity(BuildContext context) async {
    if (await canLaunchUrl(_farmersCommunityUri)) {
      await launchUrl(_farmersCommunityUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Farmers Community')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Farmer Community'),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // About section
          const Text(
            "🌱 About Farmer Community",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Farmer Community is a farmer-focused platform that helps you manage your farm, "
            "connect with fellow farmers, access marketplace services, and get expert advice "
            "on crops, livestock, and agribusiness. Our goal is to empower farmers with "
            "knowledge and practical tools to grow sustainably and profitably.",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openFarmersCommunity(context),
            child: const Text(
              "Read more",
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Help & FAQ
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.green),
            title: const Text("Help & FAQ"),
            subtitle: const Text(
              "Find answers to common questions and learn how to use Farmer Community",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openHelpFaq(context),
          ),

          // Contact
          ListTile(
            leading: const Icon(Icons.contact_mail, color: Colors.green),
            title: const Text("Contact Us"),
            subtitle: const Text(
              "Get in touch with the Farmer Community support team",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openContactUs(context),
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.green),
            title: const Text("Privacy Policy"),
            subtitle: const Text(
              "Learn how Farmer Community protects your personal information",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openPrivacyPolicy(context),
          ),

          // Terms & Conditions
          ListTile(
            leading: const Icon(Icons.description, color: Colors.green),
            title: const Text("Terms & Conditions"),
            subtitle: const Text(
              "Understand your rights and responsibilities on Farmer Community",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openTermsConditions(context),
          ),
        ],
      ),
    );
  }
}
