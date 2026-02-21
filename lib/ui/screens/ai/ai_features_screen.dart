import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/ai_providers.dart';
import '../../state/auth_provider.dart';
import '../../models/ride.dart';
import '../../services/ai/ai_ride_matching_service.dart';
import '../../services/ai/ai_pricing_service.dart';
import '../widgets/ride_match_card.dart';
import '../widgets/dynamic_pricing_card.dart';

/// AI Features Demo Screen
/// Demonstrates all AI capabilities
class AIFeaturesScreen extends ConsumerStatefulWidget {
  const AIFeaturesScreen({super.key});

  @override
  ConsumerState<AIFeaturesScreen> createState() => _AIFeaturesScreenState();
}

class _AIFeaturesScreenState extends ConsumerState<AIFeaturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Smart Match'),
            Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
            Tab(icon: Icon(Icons.route), text: 'Route'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SmartMatchTab(),
          _DynamicPricingTab(),
          _RouteOptimizationTab(),
        ],
      ),
    );
  }
}

/// Smart Match Tab
class _SmartMatchTab extends ConsumerStatefulWidget {
  const _SmartMatchTab();

  @override
  ConsumerState<_SmartMatchTab> createState() => _SmartMatchTabState();
}

class _SmartMatchTabState extends ConsumerState<_SmartMatchTab> {
  List<RideMatch>? _matches;
  bool _isLoading = false;

  Future<void> _searchWithAI() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final matchingService = ref.read(aiRideMatchingServiceProvider);

      // Mock available rides for demo
      final mockRides = <Ride>[]; // In real app, get from ride service

      final matches = await matchingService.matchRides(
        passenger: user,
        availableRides: mockRides,
      );

      setState(() => _matches = matches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.blue[50],
          child: Column(
            children: [
              const Icon(Icons.psychology, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'AI-Powered Ride Matching',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Get personalized ride recommendations based on your preferences',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchWithAI,
                icon: const Icon(Icons.search),
                label: const Text('Find Best Matches'),
              ),
            ],
          ),
        ),

        // Results
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _matches == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No matches yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap "Find Best Matches" to start',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _matches!.isEmpty
              ? const Center(child: Text('No rides available'))
              : ListView.builder(
                  itemCount: _matches!.length,
                  itemBuilder: (context, index) {
                    return RideMatchCard(
                      match: _matches![index],
                      onTap: () {
                        // Navigate to ride details
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Dynamic Pricing Tab
class _DynamicPricingTab extends ConsumerStatefulWidget {
  const _DynamicPricingTab();

  @override
  ConsumerState<_DynamicPricingTab> createState() => _DynamicPricingTabState();
}

class _DynamicPricingTabState extends ConsumerState<_DynamicPricingTab> {
  PricingRecommendation? _pricing;
  bool _isLoading = false;

  Future<void> _getPricing() async {
    setState(() => _isLoading = true);

    try {
      final pricingService = ref.read(aiPricingServiceProvider);

      // Mock data for demo
      final pricing = await pricingService.getPricingRecommendation(
        origin: Location(
          latitude: 31.5204,
          longitude: 74.3587,
          address: 'Lahore',
        ),
        destination: Location(
          latitude: 33.6844,
          longitude: 73.0479,
          address: 'Islamabad',
        ),
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        distanceKm: 380,
        currentDemand: 12,
      );

      setState(() => _pricing = pricing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.purple[50],
            child: Column(
              children: [
                const Icon(Icons.trending_up, size: 48, color: Colors.purple),
                const SizedBox(height: 12),
                const Text(
                  'Smart Pricing',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-optimized pricing based on demand, distance, and time',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getPricing,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Get Price Recommendation'),
                ),
              ],
            ),
          ),

          // Result
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_pricing != null)
            DynamicPricingCard(
              pricing: _pricing!,
              onAccept: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Price accepted!')),
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.price_check, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No pricing yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get AI-powered pricing recommendation',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Route Optimization Tab
class _RouteOptimizationTab extends StatelessWidget {
  const _RouteOptimizationTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Route Optimization',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Optimizes pickup sequences for multiple passengers to minimize distance and wait times.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.minimize,
                      text: 'Minimize total distance',
                    ),
                    _FeatureItem(
                      icon: Icons.timer,
                      text: 'Reduce passenger wait times',
                    ),
                    _FeatureItem(icon: Icons.route, text: 'Avoid backtracking'),
                    _FeatureItem(
                      icon: Icons.map,
                      text: 'Google Maps integration',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
