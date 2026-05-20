import React from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, ScrollView, Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useGetMySalons, useGetSalonStats, useGetBookings } from '@workspace/api-client-react';
import { useAuth } from '@/context/AuthContext';
import { BookingCard } from '@/components/BookingCard';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import { router } from 'expo-router';

function StatCard({ label, value, icon, color }: { label: string; value: string; icon: string; color: string }) {
  const colors = useColors();
  return (
    <View style={[styles.statCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
      <View style={[styles.statIcon, { backgroundColor: color + '20' }]}>
        <Feather name={icon as any} size={20} color={color} />
      </View>
      <Text style={[styles.statValue, { color: colors.foreground }]}>{value}</Text>
      <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>{label}</Text>
    </View>
  );
}

export default function OwnerDashboard() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { user } = useAuth();
  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;

  const { data: salons, isLoading: loadingSalons } = useGetMySalons({ query: { enabled: !!user } });
  const mySalon = salons?.[0];

  const { data: stats, isLoading: loadingStats } = useGetSalonStats(mySalon?.id ?? 0, {
    query: { enabled: !!mySalon }
  });

  const { data: recentBookings, isLoading: loadingBookings } = useGetBookings(
    { role: 'owner' },
    { query: { enabled: !!user } }
  );

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={{ paddingBottom: insets.bottom + 32 }}
      showsVerticalScrollIndicator={false}
    >
      {/* Header */}
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background }]}>
        <TouchableOpacity onPress={() => router.back()}>
          <Feather name="arrow-left" size={22} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Owner Dashboard</Text>
        <TouchableOpacity onPress={() => router.push('/owner/salon-form')}>
          <Feather name="plus" size={22} color={colors.primary} />
        </TouchableOpacity>
      </View>

      {loadingSalons ? (
        <View style={{ padding: 16 }}>
          <LoadingSkeleton width="100%" height={100} borderRadius={12} />
        </View>
      ) : !mySalon ? (
        <View style={styles.noSalon}>
          <Feather name="scissors" size={56} color={colors.mutedForeground} />
          <Text style={[styles.noSalonTitle, { color: colors.foreground }]}>No salon yet</Text>
          <Text style={[styles.noSalonText, { color: colors.mutedForeground }]}>
            Create your salon profile to start accepting bookings
          </Text>
          <TouchableOpacity
            style={[styles.createBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
            onPress={() => router.push('/owner/salon-form')}
          >
            <Text style={[styles.createBtnText, { color: colors.primaryForeground }]}>Create Salon</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <>
          {/* Salon Card */}
          <View style={[styles.salonCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
            <View style={styles.salonInfo}>
              <Text style={[styles.salonName, { color: colors.foreground }]}>{mySalon.name}</Text>
              <Text style={[styles.salonCity, { color: colors.mutedForeground }]}>{mySalon.city}</Text>
            </View>
            <View style={styles.salonActions}>
              <TouchableOpacity
                style={[styles.salonActionBtn, { backgroundColor: colors.primary + '15', borderRadius: 8 }]}
                onPress={() => router.push({ pathname: '/owner/salon-form', params: { salonId: mySalon.id } })}
              >
                <Feather name="edit-2" size={16} color={colors.primary} />
              </TouchableOpacity>
            </View>
          </View>

          {/* Stats Grid */}
          {loadingStats ? (
            <View style={styles.statsGrid}>
              {Array(4).fill(0).map((_, i) => <LoadingSkeleton key={i} width="47%" height={100} borderRadius={12} />)}
            </View>
          ) : (
            <View style={styles.statsGrid}>
              <StatCard label="Total Bookings" value={String(stats?.totalBookings ?? 0)} icon="calendar" color={colors.primary} />
              <StatCard label="Revenue" value={`$${(stats?.totalRevenue ?? 0).toFixed(0)}`} icon="dollar-sign" color="#22c55e" />
              <StatCard label="Customers" value={String(stats?.activeCustomers ?? 0)} icon="users" color="#3b82f6" />
              <StatCard label="Rating" value={`${(stats?.avgRating ?? 0).toFixed(1)} ★`} icon="star" color="#f59e0b" />
            </View>
          )}

          {/* Quick Actions */}
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Manage</Text>
            <View style={styles.actionsRow}>
              {[
                { icon: 'scissors', label: 'Services', path: `/owner/services?salonId=${mySalon.id}` },
                { icon: 'users', label: 'Staff', path: `/owner/staff?salonId=${mySalon.id}` },
                { icon: 'calendar', label: 'Bookings', path: '/(tabs)/bookings' },
              ].map((action) => (
                <TouchableOpacity
                  key={action.label}
                  style={[styles.actionCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}
                  onPress={() => router.push(action.path as any)}
                >
                  <Feather name={action.icon as any} size={22} color={colors.primary} />
                  <Text style={[styles.actionLabel, { color: colors.foreground }]}>{action.label}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Recent Bookings */}
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Recent Bookings</Text>
            {loadingBookings ? (
              Array(3).fill(0).map((_, i) => <LoadingSkeleton key={i} width="100%" height={110} borderRadius={12} style={{ marginBottom: 10 }} />)
            ) : recentBookings?.slice(0, 5).map((booking) => (
              <View key={booking.id} style={{ marginBottom: 10 }}>
                <BookingCard booking={booking} isOwnerView={true} onStatusChange={() => {}} />
              </View>
            ))}
          </View>
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 16 },
  headerTitle: { fontSize: 20, fontFamily: 'Inter_700Bold' },
  noSalon: { alignItems: 'center', paddingVertical: 80, paddingHorizontal: 32, gap: 12 },
  noSalonTitle: { fontSize: 20, fontFamily: 'Inter_600SemiBold' },
  noSalonText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center' },
  createBtn: { paddingHorizontal: 32, paddingVertical: 14, marginTop: 8 },
  createBtnText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  salonCard: { flexDirection: 'row', alignItems: 'center', marginHorizontal: 16, padding: 16, marginBottom: 16 },
  salonInfo: { flex: 1 },
  salonName: { fontSize: 18, fontFamily: 'Inter_700Bold' },
  salonCity: { fontSize: 14, fontFamily: 'Inter_400Regular', marginTop: 2 },
  salonActions: { flexDirection: 'row', gap: 8 },
  salonActionBtn: { width: 38, height: 38, alignItems: 'center', justifyContent: 'center' },
  statsGrid: { flexDirection: 'row', flexWrap: 'wrap', marginHorizontal: 16, gap: 12, marginBottom: 24 },
  statCard: { width: '47%', padding: 16, gap: 8 },
  statIcon: { width: 40, height: 40, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  statValue: { fontSize: 24, fontFamily: 'Inter_700Bold' },
  statLabel: { fontSize: 13, fontFamily: 'Inter_400Regular' },
  section: { paddingHorizontal: 16, marginBottom: 24 },
  sectionTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold', marginBottom: 12 },
  actionsRow: { flexDirection: 'row', gap: 12 },
  actionCard: { flex: 1, alignItems: 'center', padding: 20, gap: 8 },
  actionLabel: { fontSize: 13, fontFamily: 'Inter_500Medium' },
});
