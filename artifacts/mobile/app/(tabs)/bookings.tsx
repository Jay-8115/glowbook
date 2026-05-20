import React, { useState } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, FlatList, Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useGetBookings, useUpdateBookingStatus, getGetBookingsQueryKey } from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/context/AuthContext';
import { BookingCard } from '@/components/BookingCard';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import { router } from 'expo-router';
import * as Haptics from 'expo-haptics';

const TABS = [
  { label: 'Upcoming', statuses: ['pending', 'accepted', 'in_progress'] },
  { label: 'Past', statuses: ['completed', 'cancelled'] },
];

export default function BookingsScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { user, isOwner } = useAuth();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState(0);
  const [viewMode, setViewMode] = useState<'customer' | 'owner'>('customer');

  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === 'web' ? 34 + 84 : insets.bottom + 84;

  const { data: bookings, isLoading, refetch } = useGetBookings(
    { role: viewMode },
    { query: { enabled: !!user } }
  );

  const updateStatus = useUpdateBookingStatus();

  const filtered = (bookings ?? []).filter((b) => {
    const statuses = TABS[activeTab].statuses;
    return statuses.includes(b.status);
  });

  const handleStatusChange = async (bookingId: number, status: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    await updateStatus.mutateAsync({ id: bookingId, data: { status: status as any } });
    queryClient.invalidateQueries({ queryKey: getGetBookingsQueryKey() });
  };

  if (!user) {
    return (
      <View style={[styles.centered, { backgroundColor: colors.background, paddingTop: topInset }]}>
        <Feather name="calendar" size={56} color={colors.mutedForeground} />
        <Text style={[styles.emptyTitle, { color: colors.foreground }]}>Your bookings</Text>
        <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>Sign in to view your bookings</Text>
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
      {/* Header */}
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background }]}>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Bookings</Text>
        {isOwner && (
          <View style={[styles.viewToggle, { backgroundColor: colors.card, borderRadius: 8 }]}>
            {(['customer', 'owner'] as const).map((mode) => (
              <TouchableOpacity
                key={mode}
                style={[styles.toggleBtn, viewMode === mode && { backgroundColor: colors.primary }]}
                onPress={() => setViewMode(mode)}
              >
                <Text style={[styles.toggleText, { color: viewMode === mode ? colors.primaryForeground : colors.mutedForeground }]}>
                  {mode === 'customer' ? 'My Visits' : 'Salon'}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </View>

      {/* Tab selector */}
      <View style={[styles.tabRow, { borderBottomColor: colors.border }]}>
        {TABS.map((tab, i) => (
          <TouchableOpacity
            key={i}
            style={[styles.tab, activeTab === i && { borderBottomColor: colors.primary, borderBottomWidth: 2 }]}
            onPress={() => setActiveTab(i)}
          >
            <Text style={[styles.tabText, { color: activeTab === i ? colors.primary : colors.mutedForeground }]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {isLoading ? (
        <View style={{ padding: 16, gap: 12 }}>
          {Array(4).fill(0).map((_, i) => <LoadingSkeleton key={i} width="100%" height={120} borderRadius={12} />)}
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(item) => String(item.id)}
          contentContainerStyle={{ padding: 16, paddingBottom: bottomInset }}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => (
            <View style={{ marginBottom: 12 }}>
              <BookingCard
                booking={item}
                isOwnerView={viewMode === 'owner'}
                onStatusChange={handleStatusChange}
              />
            </View>
          )}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Feather name="calendar" size={48} color={colors.mutedForeground} />
              <Text style={[styles.emptyTitle, { color: colors.foreground }]}>
                {activeTab === 0 ? 'No upcoming bookings' : 'No past bookings'}
              </Text>
              {activeTab === 0 && (
                <TouchableOpacity
                  style={[styles.signInBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
                  onPress={() => router.push('/(tabs)')}
                >
                  <Text style={[styles.signInBtnText, { color: colors.primaryForeground }]}>Explore Salons</Text>
                </TouchableOpacity>
              )}
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
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 12 },
  headerTitle: { fontSize: 28, fontFamily: 'Inter_700Bold' },
  viewToggle: { flexDirection: 'row', padding: 3 },
  toggleBtn: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 6 },
  toggleText: { fontSize: 13, fontFamily: 'Inter_500Medium' },
  tabRow: { flexDirection: 'row', borderBottomWidth: 1 },
  tab: { flex: 1, alignItems: 'center', paddingVertical: 14 },
  tabText: { fontSize: 15, fontFamily: 'Inter_500Medium' },
  empty: { alignItems: 'center', paddingVertical: 80, gap: 12 },
  emptyTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },
  signInBtn: { paddingHorizontal: 32, paddingVertical: 14, marginTop: 8 },
  signInBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
});
