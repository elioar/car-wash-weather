import 'package:flutter/material.dart';

class CarWashTipsPage extends StatelessWidget {
  const CarWashTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.car_repair,
              size: 20,
              color: Color(0xFF43cea2),
            ),
            SizedBox(width: 8),
            Text(
              'Συμβουλές πλυσίματος',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF43cea2),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildTipSection(
            title: 'Προετοιμασία',
            icon: Icons.checklist_rounded,
            color: const Color(0xFF64B5F6),
            tips: [
              'Πλύνετε το αυτοκίνητο σε σκιερό μέρος',
              'Αποφύγετε το πλύσιμο σε πολύ ζεστό καιρό',
              'Βεβαιωθείτε ότι το αυτοκίνητο είναι κρύο',
              'Συγκεντρώστε όλα τα απαραίτητα υλικά',
            ],
          ),
          _buildTipSection(
            title: 'Διαδικασία πλυσίματος',
            icon: Icons.water_drop,
            color: const Color(0xFF81C784),
            tips: [
              'Ξεπλύνετε πρώτα για να απομακρύνετε τη σκόνη',
              'Χρησιμοποιήστε δύο κουβάδες (ένα για σαπούνι, ένα για ξέβγαλμα)',
              'Πλύνετε από πάνω προς τα κάτω',
              'Χρησιμοποιήστε ειδικό σφουγγάρι για αυτοκίνητα',
            ],
          ),
          _buildTipSection(
            title: 'Στέγνωμα',
            icon: Icons.dry_cleaning,
            color: const Color(0xFFBA68C8),
            tips: [
              'Χρησιμοποιήστε πετσέτα μικροϊνών',
              'Στεγνώστε γρήγορα για να αποφύγετε σημάδια',
              'Μην αφήνετε το αυτοκίνητο να στεγνώσει στον ήλιο',
              'Προσέξτε ιδιαίτερα τις γωνίες και τις εσοχές',
            ],
          ),
          _buildTipSection(
            title: 'Συχνά λάθη',
            icon: Icons.warning_rounded,
            color: const Color(0xFFE57373),
            tips: [
              'Μην πλένετε με κυκλικές κινήσεις',
              'Μην χρησιμοποιείτε απορρυπαντικό πιάτων',
              'Μην πλένετε σε άμεσο ηλιακό φως',
              'Μην αφήνετε το σαπούνι να στεγνώσει',
            ],
          ),
          _buildTipSection(
            title: 'Διατήρηση Υγείας Αυτοκινήτου',
            icon: Icons.health_and_safety,
            color: const Color(0xFF4DB6AC),
            tips: [
              'Ελέγχετε τακτικά την πίεση των ελαστικών',
              'Αλλάζετε λάδια κάθε 5,000 χιλιόμετρα',
              'Καθαρίζετε τα φίλτρα αέρα κάθε 10,000 χιλιόμετρα',
              'Ελέγχετε τα φρένα κάθε 15,000 χιλιόμετρα',
            ],
          ),
          _buildTipSection(
            title: 'Συμβουλές για Καύσιμα',
            icon: Icons.local_gas_station,
            color: const Color(0xFFFFB74D),
            tips: [
              'Χρησιμοποιήστε καύσιμα υψηλής ποιότητας για καλύτερη απόδοση.',
              'Αποφύγετε την υπερβολική επιτάχυνση για εξοικονόμηση καυσίμου.',
              'Ελέγχετε τακτικά το καπάκι του ρεζερβουάρ για διαρροές.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> tips,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          children: tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${tips.indexOf(tip) + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
