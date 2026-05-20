import React from 'react';
import { StyleSheet, View, Text, ScrollView, Platform, RefreshControl } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColors } from '@/hooks/useColors';
import { useGetCategories, useGetFeaturedSalons } from '@workspace/api-client-react';
import { CategoryChip } from '@/components/CategoryChip';
import { SalonCard } from '@/components/SalonCard';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';

export default function HomeScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  
  const { data: categories, isLoading: isLoadingCategories, refetch: refetchCategories } = useGetCategories();
  const { data: featured, isLoading: isLoadingFeatured, refetch: refetchFeatured } = useGetFeaturedSalons();
  
  const [refreshing, setRefreshing] = React.useState(false);

  const onRefresh = React.useCallback(async () => {
    setRefreshing(true);
    await Promise.all([refetchCategories(), refetchFeatured()]);
    setRefreshing(false);
  }, [refetchCategories, refetchFeatured]);

  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === 'web' ? Math.max(insets.bottom, 34) + 84 : insets.bottom + 84;

  const handleCategoryPress = (categoryName: string) => {
    router.push(`/search?category=${encodeURIComponent(categoryName)}`);
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background }]}>
        <View style={styles.headerContent}>
          <Text style={[styles.logo, { color: colors.primary }]}>GlowBook</Text>
          <View style={styles.locationContainer}>
            <Feather name="map-pin" size={14} color={colors.mutedForeground} />
            <Text style={[styles.locationText, { color: colors.foreground }]}>Current Location</Text>
          </View>
        </View>
      </View>

      <ScrollView
        contentContainerStyle={{ paddingBottom: bottomInset }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />
        }
      >
        <View style={styles.searchContainer}>
          <View style={[styles.searchBar, { backgroundColor: colors.input, borderRadius: colors.radius }]}>
            <Feather name="search" size={20} color={colors.mutedForeground} />
            <Text style={[styles.searchText, { color: colors.mutedForeground }]} onPress={() => router.push('/search')}>
              Search salons, stylists, services...
            </Text>
          </View>
        </View>

        <View style={styles.categoriesContainer}>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.categoriesScroll}>
            {isLoadingCategories ? (
              Array(4).fill(0).map((_, i) => <LoadingSkeleton key={i} width={100} height={40} borderRadius={20} />)
            ) : (
              categories?.map((cat) => (
                <CategoryChip
                  key={cat.id}
                  name={cat.name}
                  iconName={cat.icon as any}
                  onPress={() => handleCategoryPress(cat.name)}
                />
              ))
            )}
          </ScrollView>
        </View>

        {isLoadingFeatured ? (
          <View style={styles.loadingSection}>
            <LoadingSkeleton width={150} height={24} style={{ marginBottom: 16, marginLeft: 16 }} />
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.horizontalScroll}>
              {Array(3).fill(0).map((_, i) => <LoadingSkeleton key={i} width={280} height={260} style={{ marginRight: 16 }} />)}
            </ScrollView>
          </View>
        ) : (
          <>
            {featured?.trending && featured.trending.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Trending Now</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.horizontalScroll}>
                  {featured.trending.map((salon) => (
                    <View key={salon.id} style={styles.cardWrapper}>
                      <SalonCard salon={salon} horizontal />
                    </View>
                  ))}
                </ScrollView>
              </View>
            )}

            {featured?.nearby && featured.nearby.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Nearby Salons</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.horizontalScroll}>
                  {featured.nearby.map((salon) => (
                    <View key={salon.id} style={styles.cardWrapper}>
                      <SalonCard salon={salon} horizontal />
                    </View>
                  ))}
                </ScrollView>
              </View>
            )}

            {featured?.topRated && featured.topRated.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Top Rated</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.horizontalScroll}>
                  {featured.topRated.map((salon) => (
                    <View key={salon.id} style={styles.cardWrapper}>
                      <SalonCard salon={salon} horizontal />
                    </View>
                  ))}
                </ScrollView>
              </View>
            )}
          </>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 16,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'transparent', // Make opaque if you want a divider
    zIndex: 10,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logo: {
    fontSize: 24,
    fontFamily: 'Inter_700Bold',
  },
  locationContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  locationText: {
    fontSize: 14,
    fontFamily: 'Inter_500Medium',
  },
  searchContainer: {
    padding: 16,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    height: 52,
    gap: 12,
  },
  searchText: {
    fontSize: 16,
    fontFamily: 'Inter_400Regular',
    flex: 1,
  },
  categoriesContainer: {
    marginBottom: 24,
  },
  categoriesScroll: {
    paddingHorizontal: 16,
    gap: 12,
  },
  loadingSection: {
    marginBottom: 32,
  },
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 20,
    fontFamily: 'Inter_600SemiBold',
    marginLeft: 16,
    marginBottom: 16,
  },
  horizontalScroll: {
    paddingHorizontal: 16,
  },
  cardWrapper: {
    marginRight: 16,
  },
});