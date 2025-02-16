import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verein_app/models/season.dart';
import 'package:verein_app/providers/season_provider.dart';
import 'package:verein_app/providers/team_result_provider.dart';

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
  _FilterSectionState createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
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
            child: DropdownButtonFormField<SaisonData>(
              value: _selectedSeason,
              items: saisonList.map((saisonData) {
                return DropdownMenuItem<SaisonData>(
                  value: saisonData,
                  child: Text(saisonData.saison),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    lsProvider.loadLigaSpieleForSeason(value);
                    _selectedSeason = value;
                    //  _selectedAgeGroup = "Alle";
                  });
                  widget.onSeasonChanged(value);
                }
              },
              decoration: const InputDecoration(
                labelText: "Saison",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10), // Abstand zwischen den Dropdowns

          // Altersklassen-Dropdown (50% Breite)
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedAgeGroup,
              items: ageGroups.map((group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                  widget.onAgeGroupChanged(value);
                }
              },
              decoration: const InputDecoration(
                labelText: "Altersklasse",
                border: OutlineInputBorder(),
              ),
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
