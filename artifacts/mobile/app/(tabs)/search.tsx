import React, { useState, useRef } from 'react';
import {
  StyleSheet, View, Text, TextInput, TouchableOpacity,
  FlatList, Platform, ActivityIndicator,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useGetSalons } from '@workspace/api-client-react';
import { SalonCard } from '@/components/SalonCard';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import { router, useLocalSearchParams } from 'expo-router';

const SORT_OPTIONS = [
  { label: 'Top Rated', value: 'rating' },
  { label: 'Nearest', value: 'distance' },
];

export default function SearchScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const params = useLocalSearchParams<{ category?: string }>();

  const [query, setQuery] = useState('');
  const [minRating, setMinRating] = useState<number | undefined>(undefined);
  const [sortBy, setSortBy] = useState<string | undefined>(undefined);
  const inputRef = useRef<TextInput>(null);

  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === 'web' ? 34 + 84 : insets.bottom + 84;

  const { data, isLoading, refetch } = useGetSalons(
    { search: query || undefined, minRating, sortBy: sortBy as any },
    { query: { enabled: true } }
  );

  const salons = data?.salons ?? [];

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Search Header */}
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background, borderBottomColor: colors.border }]}>
        <View style={[styles.searchRow, { backgroundColor: colors.input, borderRadius: colors.radius }]}>
          <Feather name="search" size={18} color={colors.mutedForeground} />
          <TextInput
            ref={inputRef}
            style={[styles.searchInput, { color: colors.foreground, fontFamily: 'Inter_400Regular' }]}
            placeholder="Salons, services, stylists..."
            placeholderTextColor={colors.mutedForeground}
            value={query}
            onChangeText={setQuery}
            returnKeyType="search"
            autoCorrect={false}
          />
          {query.length > 0 && (
            <TouchableOpacity onPress={() => setQuery('')}>
              <Feather name="x" size={18} color={colors.mutedForeground} />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Filter chips */}
      <View style={styles.filtersRow}>
        {SORT_OPTIONS.map((opt) => (
          <TouchableOpacity
            key={opt.value}
            style={[styles.filterChip, {
              backgroundColor: sortBy === opt.value ? colors.primary : colors.card,
              borderColor: sortBy === opt.value ? colors.primary : colors.border,
              borderRadius: 20,
            }]}
            onPress={() => setSortBy(sortBy === opt.value ? undefined : opt.value)}
          >
            <Text style={[styles.filterChipText, { color: sortBy === opt.value ? colors.primaryForeground : colors.foreground }]}>
              {opt.label}
            </Text>
          </TouchableOpacity>
        ))}
        {[4, 4.5].map((r) => (
          <TouchableOpacity
            key={r}
            style={[styles.filterChip, {
              backgroundColor: minRating === r ? colors.primary : colors.card,
              borderColor: minRating === r ? colors.primary : colors.border,
              borderRadius: 20,
            }]}
            onPress={() => setMinRating(minRating === r ? undefined : r)}
          >
            <Feather name="star" size={12} color={minRating === r ? colors.primaryForeground : colors.primary} />
            <Text style={[styles.filterChipText, { color: minRating === r ? colors.primaryForeground : colors.foreground }]}>
              {r}+
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {isLoading ? (
        <View style={styles.loadingList}>
          {Array(5).fill(0).map((_, i) => (
            <LoadingSkeleton key={i} width="100%" height={100} style={{ marginBottom: 12 }} borderRadius={12} />
          ))}
        </View>
      ) : (
        <FlatList
          data={salons}
          keyExtractor={(item) => String(item.id)}
          contentContainerStyle={{ padding: 16, paddingBottom: bottomInset }}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => (
            <View style={{ marginBottom: 16 }}>
              <SalonCard salon={item}  />
            </View>
          )}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Feather name="search" size={48} color={colors.mutedForeground} />
              <Text style={[styles.emptyTitle, { color: colors.foreground }]}>No salons found</Text>
              <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
                Try adjusting your search or filters
              </Text>
            </View>
          }
          ListHeaderComponent={
            data?.total ? (
              <Text style={[styles.resultCount, { color: colors.mutedForeground }]}>
                {data.total} salon{data.total !== 1 ? 's' : ''} found
              </Text>
            ) : null
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 16, paddingBottom: 12, borderBottomWidth: 1 },
  searchRow: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 14, height: 48, gap: 10 },
  searchInput: { flex: 1, fontSize: 15, height: 48 },
  filtersRow: { flexDirection: 'row', paddingHorizontal: 16, paddingVertical: 12, gap: 8, flexWrap: 'wrap' },
  filterChip: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 14, paddingVertical: 7, borderWidth: 1, gap: 4 },
  filterChipText: { fontSize: 13, fontFamily: 'Inter_500Medium' },
  loadingList: { padding: 16 },
  empty: { alignItems: 'center', paddingVertical: 80, gap: 12 },
  emptyTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },
  resultCount: { fontSize: 13, fontFamily: 'Inter_400Regular', marginBottom: 12 },
});
