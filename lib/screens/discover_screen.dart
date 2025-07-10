import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildPollutantsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Discover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Learn about air pollutants and their health impacts',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantsList() {
    final pollutants = [
      {
        'name': 'PM2.5',
        'fullName': 'Fine Particulate Matter',
        'unit': 'μg/m³',
        'icon': Icons.cloud,
        'color': Colors.orange,
        'description':
            'Particles smaller than 2.5 micrometers that can penetrate deep into the lungs',
        'healthEffects': [
          'Respiratory problems',
          'Cardiovascular disease',
          'Lung cancer',
          'Premature death'
        ],
        'sources': [
          'Vehicle emissions',
          'Industrial processes',
          'Burning of fossil fuels',
          'Wildfires'
        ],
        'protection': [
          'Use air purifiers with HEPA filters',
          'Stay indoors during high pollution days',
          'Wear N95 masks outdoors',
          'Avoid outdoor exercise in polluted areas'
        ]
      },
      {
        'name': 'PM10',
        'fullName': 'Coarse Particulate Matter',
        'unit': 'μg/m³',
        'icon': Icons.cloud_queue,
        'color': Colors.red,
        'description':
            'Particles between 2.5 and 10 micrometers that can irritate the respiratory system',
        'healthEffects': [
          'Eye and throat irritation',
          'Coughing and sneezing',
          'Aggravation of asthma',
          'Respiratory infections'
        ],
        'sources': [
          'Dust from roads and construction',
          'Pollen and mold spores',
          'Industrial emissions',
          'Agricultural activities'
        ],
        'protection': [
          'Keep windows closed during dust storms',
          'Use air conditioning with filters',
          'Clean indoor surfaces regularly',
          'Avoid outdoor activities in dusty conditions'
        ]
      },
      {
        'name': 'O₃',
        'fullName': 'Ozone',
        'unit': 'ppb',
        'icon': Icons.wb_sunny,
        'color': Colors.purple,
        'description':
            'A gas formed when sunlight reacts with vehicle and industrial emissions',
        'healthEffects': [
          'Chest pain and coughing',
          'Throat irritation',
          'Reduced lung function',
          'Aggravation of asthma'
        ],
        'sources': [
          'Vehicle exhaust',
          'Industrial emissions',
          'Chemical solvents',
          'Natural sources (lightning)'
        ],
        'protection': [
          'Limit outdoor activities during peak ozone hours',
          'Use public transportation',
          'Avoid using gas-powered equipment',
          'Stay indoors with air conditioning'
        ]
      },
      {
        'name': 'NO₂',
        'fullName': 'Nitrogen Dioxide',
        'unit': 'ppb',
        'icon': Icons.local_gas_station,
        'color': Colors.brown,
        'description':
            'A reddish-brown gas that forms from burning fossil fuels',
        'healthEffects': [
          'Respiratory inflammation',
          'Increased asthma attacks',
          'Reduced lung function',
          'Respiratory infections'
        ],
        'sources': [
          'Vehicle emissions',
          'Power plants',
          'Industrial boilers',
          'Gas stoves and heaters'
        ],
        'protection': [
          'Use electric or induction cooking',
          'Ensure proper ventilation',
          'Maintain vehicles regularly',
          'Support clean energy initiatives'
        ]
      },
      {
        'name': 'SO₂',
        'fullName': 'Sulfur Dioxide',
        'unit': 'ppb',
        'icon': Icons.factory,
        'color': Colors.grey,
        'description':
            'A colorless gas with a sharp odor that forms from burning sulfur-containing fuels',
        'healthEffects': [
          'Eye and throat irritation',
          'Coughing and wheezing',
          'Bronchitis and asthma attacks',
          'Respiratory infections'
        ],
        'sources': [
          'Coal-fired power plants',
          'Industrial processes',
          'Ship emissions',
          'Volcanic eruptions'
        ],
        'protection': [
          'Support clean energy policies',
          'Use energy-efficient appliances',
          'Reduce electricity consumption',
          'Stay informed about air quality alerts'
        ]
      },
      {
        'name': 'CO',
        'fullName': 'Carbon Monoxide',
        'unit': 'ppb',
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'description':
            'A colorless, odorless gas that reduces oxygen delivery to the body',
        'healthEffects': [
          'Headaches and dizziness',
          'Nausea and confusion',
          'Chest pain',
          'Fatal at high levels'
        ],
        'sources': [
          'Vehicle exhaust',
          'Gas stoves and heaters',
          'Tobacco smoke',
          'Industrial processes'
        ],
        'protection': [
          'Install CO detectors at home',
          'Ensure proper ventilation',
          'Maintain heating systems',
          'Never run vehicles in enclosed spaces'
        ]
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: pollutants.length,
      itemBuilder: (context, index) {
        final pollutant = pollutants[index];
        return _buildPollutantCard(pollutant);
      },
    );
  }

  Widget _buildPollutantCard(Map<String, dynamic> pollutant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2454),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (pollutant['color'] as Color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPollutantDetails(pollutant),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (pollutant['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    pollutant['icon'] as IconData,
                    color: pollutant['color'] as Color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pollutant['name'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pollutant['fullName'] as String,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pollutant['description'] as String,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPollutantDetails(Map<String, dynamic> pollutant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPollutantDetailsSheet(pollutant),
    );
  }

  Widget _buildPollutantDetailsSheet(Map<String, dynamic> pollutant) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0E2454),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (pollutant['color'] as Color)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          pollutant['icon'] as IconData,
                          color: pollutant['color'] as Color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pollutant['name'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              pollutant['fullName'] as String,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildDetailSection(
                    'What is ${pollutant['name']}?',
                    pollutant['description'] as String,
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 20),

                  // Health Effects
                  _buildDetailSection(
                    'Health Effects',
                    '',
                    Icons.health_and_safety,
                    isList: true,
                    listItems: pollutant['healthEffects'] as List<String>,
                  ),
                  const SizedBox(height: 20),

                  // Sources
                  _buildDetailSection(
                    'Common Sources',
                    '',
                    Icons.source,
                    isList: true,
                    listItems: pollutant['sources'] as List<String>,
                  ),
                  const SizedBox(height: 20),

                  // Protection
                  _buildDetailSection(
                    'How to Protect Yourself',
                    '',
                    Icons.shield,
                    isList: true,
                    listItems: pollutant['protection'] as List<String>,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    IconData icon, {
    bool isList = false,
    List<String>? listItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isList && listItems != null)
          ...listItems
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList()
        else
          Text(
            content,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}
