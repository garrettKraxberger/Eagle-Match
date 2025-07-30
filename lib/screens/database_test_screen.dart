import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String _testResult = 'Testing database connection...';

  @override
  void initState() {
    super.initState();
    _testDatabase();
  }

  Future<void> _testDatabase() async {
    try {
      // Test 1: Check if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _testResult = '❌ User not authenticated. Please log in first.';
        });
        return;
      }

      setState(() {
        _testResult = '✅ User authenticated: ${user.email}\n\nTesting database tables...';
      });

      // Test 2: Check if user has a profile
      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _testResult += '\n✅ User profile exists: ${profileResponse['full_name'] ?? 'No name'}';
          _testResult += '\n   Profile ID: ${profileResponse['id']}';
          _testResult += '\n   Created at: ${profileResponse['created_at']}';
        });
      } catch (e) {
        setState(() {
          _testResult += '\n❌ User profile missing: $e';
          _testResult += '\n   User ID: ${user.id}';
          _testResult += '\n   User email: ${user.email}';
          _testResult += '\n   Creating profile...';
        });
        
        try {
          final insertResponse = await Supabase.instance.client
              .from('profiles')
              .insert({
                'id': user.id,
                'full_name': user.email?.split('@')[0] ?? 'Test User',
                'age': 25,
                'handicap': 15.0,
                'location': 'Test Location',
              })
              .select()
              .single();
          
          setState(() {
            _testResult += '\n✅ Profile created successfully!';
            _testResult += '\n   New profile: ${insertResponse['full_name']}';
          });

          // Small delay to ensure the insert is committed
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify the profile was created by reading it back
          try {
            final verifyProfile = await Supabase.instance.client
                .from('profiles')
                .select('*')
                .eq('id', user.id)
                .single();
            
            setState(() {
              _testResult += '\n✅ Profile verification: ${verifyProfile['full_name'] ?? 'No name'}';
            });
          } catch (verifyError) {
            setState(() {
              _testResult += '\n❌ Profile verification failed: $verifyError';
            });
            
            // Try to check if profile exists with a different approach
            try {
              final allProfiles = await Supabase.instance.client
                  .from('profiles')
                  .select('*')
                  .eq('id', user.id);
              
              setState(() {
                _testResult += '\n   Profile check result: ${allProfiles.length} profiles found';
                if (allProfiles.isNotEmpty) {
                  _testResult += '\n   Found profile: ${allProfiles.first}';
                }
              });
            } catch (checkError) {
              setState(() {
                _testResult += '\n   Profile recheck failed: $checkError';
              });
            }
          }

        } catch (createError) {
          setState(() {
            _testResult += '\n❌ Failed to create profile: $createError';
          });
          return;
        }
      }

      // Test 3: Check if matches table exists
      try {
        await Supabase.instance.client
            .from('matches')
            .select('count')
            .limit(1);
        
        setState(() {
          _testResult += '\n✅ Matches table exists';
        });
      } catch (e) {
        setState(() {
          _testResult += '\n❌ Matches table missing: $e';
        });
        return;
      }

      // Test 4: Check if counties table exists
      try {
        await Supabase.instance.client
            .from('counties')
            .select('count')
            .limit(1);
        
        setState(() {
          _testResult += '\n✅ Counties table exists';
        });
      } catch (e) {
        setState(() {
          _testResult += '\n❌ Counties table missing: $e';
        });
      }

      // Test 5: Check if courses table exists
      try {
        await Supabase.instance.client
            .from('courses')
            .select('count')
            .limit(1);
        
        setState(() {
          _testResult += '\n✅ Courses table exists';
        });
      } catch (e) {
        setState(() {
          _testResult += '\n❌ Courses table missing: $e';
        });
      }

      // Test 6: Check if partnerships table exists (for duos screen)
      try {
        await Supabase.instance.client
            .from('partnerships')
            .select('count')
            .limit(1);
        
        setState(() {
          _testResult += '\n✅ Partnerships table exists (duos screen ready)';
        });
        
        // Test partnerships data
        try {
          final partnerships = await Supabase.instance.client
              .from('partnerships')
              .select('id, matches_played, matches_won, is_starred, status')
              .limit(5);
          
          setState(() {
            _testResult += '\n✅ Partnerships data: ${partnerships.length} partnerships found';
            if (partnerships.isNotEmpty) {
              final partnership = partnerships[0];
              _testResult += '\n   Sample partnership: ${partnership['matches_played']} matches played, ${partnership['matches_won']} won';
            }
          });
        } catch (dataError) {
          setState(() {
            _testResult += '\n⚠️  Partnerships table exists but has no data yet';
          });
        }
      } catch (e) {
        setState(() {
          _testResult += '\n❌ Partnerships table missing: $e';
          _testResult += '\n   💡 Run setup_partnerships_table.sql in Supabase to enable duos screen';
        });
      }

      // Test 7: Test courses and counties data
      try {
        final courses = await Supabase.instance.client
            .from('courses')
            .select('id, name')
            .limit(5);
        
        final counties = await Supabase.instance.client
            .from('counties')
            .select('id, county, state')
            .limit(5);
            
        setState(() {
          _testResult += '\n✅ Sample courses: ${courses.length} found';
          _testResult += '\n✅ Sample counties: ${counties.length} found';
          if (courses.isNotEmpty) {
            _testResult += '\n   First course: ${courses[0]['name']} (ID: ${courses[0]['id']})';
          }
          if (counties.isNotEmpty) {
            _testResult += '\n   First county: ${counties[0]['county']}, ${counties[0]['state']} (ID: ${counties[0]['id']})';
          }
        });
      } catch (e) {
        setState(() {
          _testResult += '\n❌ Error loading location data: $e';
        });
      }

      // Test 8: Test inserting a match with proper location_ids
      try {
        // Get a valid county ID first
        final countyData = await Supabase.instance.client
            .from('counties')
            .select('id')
            .limit(1);
            
        if (countyData.isEmpty) {
          setState(() {
            _testResult += '\n❌ No counties available for testing';
          });
          return;
        }

        final testMatch = {
          'creator_id': user.id,
          'match_type': 'Match Play',
          'match_mode': 'Single',
          'location_mode': 'counties',
          'location_ids': [countyData[0]['id']], // Use a valid county ID
          'schedule_mode': 'specific',
          'date': DateTime.now().toIso8601String(),
          'time': '10:00 AM',
          'handicap_required': false,
          'is_private': false,
        };

        await Supabase.instance.client
            .from('matches')
            .insert(testMatch);

        setState(() {
          _testResult += '\n✅ Test match insert successful!';
        });

        // Test 9: Test inserting a match with custom course
        final testCustomCourseMatch = {
          'creator_id': user.id,
          'match_type': 'Stroke Play',
          'match_mode': 'Single',
          'location_mode': 'course',
          'location_ids': [-1], // Special indicator for custom course
          'custom_course_name': 'My Local Golf Course',
          'custom_course_city': 'My Town',
          'schedule_mode': 'flexible',
          'days_of_week': ['Saturday', 'Sunday'],
          'handicap_required': true,
          'is_private': false,
        };

        await Supabase.instance.client
            .from('matches')
            .insert(testCustomCourseMatch);

        setState(() {
          _testResult += '\n✅ Test custom course match insert successful!';
        });

        // Clean up - delete both test matches
        await Supabase.instance.client
            .from('matches')
            .delete()
            .eq('creator_id', user.id)
            .in_('match_type', ['Match Play', 'Stroke Play']);

        setState(() {
          _testResult += '\n✅ Test cleanup successful!';
          _testResult += '\n\n🎉 Database is ready for match posting!';
          _testResult += '\n   • County-based matches: ✅';
          _testResult += '\n   • Custom course matches: ✅';
        });

      } catch (e) {
        if (mounted) {
          setState(() {
            _testResult += '\n❌ Test match insert failed: $e';
          });
        }
      }

    } catch (error) {
      if (mounted) {
        setState(() {
          _testResult = '❌ Database test failed: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Connection Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_testResult),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testResult = 'Retesting database connection...';
                });
                _testDatabase();
              },
              child: const Text('Retest Database'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final profile = await SupabaseService.getOrCreateUserProfile();
                setState(() {
                  _testResult += '\n\n=== PROFILE SERVICE TEST ===';
                  if (profile != null) {
                    _testResult += '\n✅ Profile service working: ${profile['full_name']}';
                    _testResult += '\n   Profile data: $profile';
                  } else {
                    _testResult += '\n❌ Profile service failed';
                  }
                });
              },
              child: const Text('Test Profile Service'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _testResult += '\n\n=== PARTNERSHIP CREATION TEST ===';
                });
                
                try {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId == null) {
                    setState(() {
                      _testResult += '\n❌ No authenticated user';
                    });
                    return;
                  }

                  // Get another user from the database for testing
                  final otherUsers = await Supabase.instance.client
                      .from('profiles')
                      .select('id, full_name')
                      .neq('id', userId)
                      .limit(1);

                  if (otherUsers.isEmpty) {
                    setState(() {
                      _testResult += '\n❌ No other users found for partnership test';
                    });
                    return;
                  }

                  final otherUserId = otherUsers[0]['id'] as String;
                  final otherUserName = otherUsers[0]['full_name'] as String;

                  setState(() {
                    _testResult += '\n🧪 Testing partnership creation...';
                    _testResult += '\n   Current user: $userId';
                    _testResult += '\n   Partner: $otherUserName ($otherUserId)';
                  });

                  // Test creating a partnership using our service
                  final partnership = await SupabaseService.createOrUpdatePartnership(
                    user1Id: userId,
                    user2Id: otherUserId,
                    incrementMatches: true,
                    incrementWins: false,
                  );

                  if (partnership != null) {
                    setState(() {
                      _testResult += '\n✅ Partnership created/updated successfully!';
                      _testResult += '\n   Partnership ID: ${partnership['id']}';
                      _testResult += '\n   Matches played: ${partnership['matches_played']}';
                      _testResult += '\n   Matches won: ${partnership['matches_won']}';
                      _testResult += '\n   Win percentage: ${partnership['matches_played'] > 0 ? ((partnership['matches_won'] / partnership['matches_played']) * 100).toStringAsFixed(1) : '0'}%';
                    });
                  } else {
                    setState(() {
                      _testResult += '\n❌ Partnership creation failed';
                    });
                  }

                  // Now test incrementing wins
                  setState(() {
                    _testResult += '\n\n🧪 Testing partnership win update...';
                  });

                  final updatedPartnership = await SupabaseService.createOrUpdatePartnership(
                    user1Id: userId,
                    user2Id: otherUserId,
                    incrementMatches: true,
                    incrementWins: true,
                  );

                  if (updatedPartnership != null) {
                    setState(() {
                      _testResult += '\n✅ Partnership updated with win!';
                      _testResult += '\n   Matches played: ${updatedPartnership['matches_played']}';
                      _testResult += '\n   Matches won: ${updatedPartnership['matches_won']}';
                      _testResult += '\n   New win percentage: ${updatedPartnership['matches_played'] > 0 ? ((updatedPartnership['matches_won'] / updatedPartnership['matches_played']) * 100).toStringAsFixed(1) : '0'}%';
                    });
                  }

                } catch (error) {
                  setState(() {
                    _testResult += '\n❌ Partnership test failed: $error';
                  });
                }
              },
              child: const Text('Test Partnership Creation'),
            ),
          ],
        ),
      ),
    );
  }
}
