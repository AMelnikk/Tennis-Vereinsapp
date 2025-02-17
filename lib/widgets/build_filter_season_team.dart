import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/utils/app_utils.dart';
import '../models/season.dart';
import '../providers/season_provider.dart';
import '../providers/team_result_provider.dart';

class FilterSection extends StatefulWidget {
  final SaisonData selectedSeason;
  final String selectedAgeGroup;
  final Function(SaisonData) onSeasonChanged;
  final Function(String) onAgeGroupChanged;

  const FilterSection({
    super.key,
    required this.selectedSeason,
    required this.selectedAgeGroup,
    required this.onSeasonChanged,
    required this.onAgeGroupChanged,
  });

  @override
  FilterSectionState createState() => FilterSectionState();
}

class FilterSectionState extends State<FilterSection> {
  late SaisonData _selectedSeason;
  late String _selectedAgeGroup;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.selectedSeason;
    _selectedAgeGroup = widget.selectedAgeGroup;
  }

  @override
  Widget build(BuildContext context) {
    final saisonProvider = Provider.of<SaisonProvider>(context);
    final lsProvider = Provider.of<LigaSpieleProvider>(context);
    final List<SaisonData> saisonList = saisonProvider.saisons;

    if (saisonList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedSeason.jahr == -1 && saisonList.isNotEmpty) {
      _selectedSeason = saisonList.first;
    }

    List<String> ageGroups = getAgeGroups(lsProvider, _selectedSeason);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          // Saison-Dropdown (50% Breite)
          Expanded(
            child: buildDropdownField(
              label: "Saison",
              value: _selectedSeason.saison,
              items: saisonList.map((saisonData) => saisonData.saison).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedSaison = saisonList.firstWhere(
                      (saison) => saison.saison == value,
                      orElse: () => saisonList.first);
                  setState(() {
                    lsProvider.loadLigaSpieleForSeason(selectedSaison);
                    _selectedSeason = selectedSaison;
                  });
                  widget.onSeasonChanged(selectedSaison);
                }
              },
            ),
          ),
          const SizedBox(width: 10), // Abstand zwischen den Dropdowns

          // Altersklassen-Dropdown (50% Breite)
          Expanded(
            child: buildDropdownField(
              label: "Altersklasse",
              value: _selectedAgeGroup,
              items: ageGroups,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                  widget.onAgeGroupChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<String> getAgeGroups(
      LigaSpieleProvider lsProvider, SaisonData selectedSeason) {
    final aks = lsProvider
        .getFilteredSpiele(
          saisonKey: selectedSeason.key,
          jahr: null,
          altersklasse: null,
        )
        .map((spiel) => spiel.altersklasse)
        .toSet()
        .toList();

    return [
      "Alle",
      if (aks.isNotEmpty) ...aks,
    ];
  }
}
