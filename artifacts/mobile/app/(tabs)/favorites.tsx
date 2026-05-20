import React from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, FlatList, Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useGetFavorites } from '@workspace/api-client-react';
import { useAuth } from '@/context/AuthContext';
import { SalonCard } from '@/components/SalonCard';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import { router } from 'expo-router';

export default function FavoritesScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { user } = useAuth();

  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === 'web' ? 34 + 84 : insets.bottom + 84;

  const { data: favorites, isLoading } = useGetFavorites({ query: { enabled: !!user } });

  if (!user) {
    return (
      <View style={[styles.centered, { backgroundColor: colors.background, paddingTop: topInset }]}>
        <Ionicons name="heart-outline" size={56} color={colors.mutedForeground} />
        <Text style={[styles.emptyTitle, { color: colors.foreground }]}>Saved Salons</Text>
        <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>Sign in to save your favorite salons</Text>
        <TouchableOpacity
          style={[styles.signInBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
          onPress={() => router.push('/auth/login')}
        >
          <Text style={[styles.signInBtnText, { color: colors.primaryForeground }]}>Sign In</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topInset }]}>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Saved</Text>
      </View>

      {isLoading ? (
        <View style={{ padding: 16, gap: 12 }}>
          {Array(4).fill(0).map((_, i) => (
            <LoadingSkeleton key={i} width="100%" height={100} borderRadius={12} />
          ))}
        </View>
      ) : (
        <FlatList
          data={favorites ?? []}
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
              <Ionicons name="heart-outline" size={56} color={colors.mutedForeground} />
              <Text style={[styles.emptyTitle, { color: colors.foreground }]}>No saved salons yet</Text>
              <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
                Tap the heart icon on any salon to save it here
              </Text>
              <TouchableOpacity
                style={[styles.signInBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
                onPress={() => router.push('/(tabs)')}
              >
                <Text style={[styles.signInBtnText, { color: colors.primaryForeground }]}>Explore Salons</Text>
              </TouchableOpacity>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  centered: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16, paddingHorizontal: 32 },
  header: { paddingHorizontal: 16, paddingBottom: 12 },
  headerTitle: { fontSize: 28, fontFamily: 'Inter_700Bold' },
  empty: { alignItems: 'center', paddingVertical: 80, gap: 12 },
  emptyTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },
  signInBtn: { paddingHorizontal: 32, paddingVertical: 14, marginTop: 8 },
  signInBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
});
