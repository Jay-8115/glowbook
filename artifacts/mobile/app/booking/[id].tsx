import React, { useCallback } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, ScrollView, Platform,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { useGetBooking, useUpdateBookingStatus, getGetBookingsQueryKey } from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/context/AuthContext';
import { StatusBadge } from '@/components/StatusBadge';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import * as Haptics from 'expo-haptics';

export default function BookingDetailScreen() {
  const { id: rawId } = useLocalSearchParams<{ id: string }>();
  const id = parseInt(rawId ?? '0', 10);
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;

  const { data: booking, isLoading } = useGetBooking(id, { query: { enabled: !!id } });
  const updateStatus = useUpdateBookingStatus();

  const handleCancel = useCallback(async () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    await updateStatus.mutateAsync({ id, data: { status: 'cancelled' } });
    queryClient.invalidateQueries({ queryKey: getGetBookingsQueryKey() });
    router.back();
  }, [id, updateStatus, queryClient]);

  if (isLoading || !booking) {
    return (
      <View style={[styles.container, { backgroundColor: colors.background, paddingTop: topInset }]}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()}>
            <Feather name="arrow-left" size={22} color={colors.foreground} />
          </TouchableOpacity>
        </View>
        <View style={{ padding: 16, gap: 12 }}>
          <LoadingSkeleton width="100%" height={200} borderRadius={12} />
        </View>
      </View>
    );
  }

  const canCancel = booking.status === 'pending' || booking.status === 'accepted';

  const formattedDate = (() => {
    try {
      return new Date(booking.bookingDate).toLocaleDateString('en-US', {
        weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
      });
    } catch {
      return booking.bookingDate;
    }
  })();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topInset, borderBottomColor: colors.border }]}>
        <TouchableOpacity onPress={() => router.back()}>
          <Feather name="arrow-left" size={22} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Booking Details</Text>
        <View style={{ width: 22 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Status */}
        <View style={[styles.statusCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
          <View style={styles.statusRow}>
            <Text style={[styles.statusLabel, { color: colors.mutedForeground }]}>Status</Text>
            <StatusBadge status={booking.status} />
          </View>
          <Text style={[styles.bookingId, { color: colors.mutedForeground }]}>
            Booking #{booking.id}
          </Text>
        </View>

        {/* Details */}
        <View style={[styles.detailCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
          {booking.salon && (
            <DetailRow icon="scissors" label="Salon" value={booking.salon.name} colors={colors} />
          )}
          {booking.service && (
            <DetailRow icon="tag" label="Service" value={booking.service.name} colors={colors} />
          )}
          {booking.staff && (
            <DetailRow icon="user" label="Stylist" value={booking.staff.name} colors={colors} />
          )}
          <DetailRow icon="calendar" label="Date" value={formattedDate} colors={colors} />
          <DetailRow icon="clock" label="Time" value={`${booking.startTime}${booking.endTime ? ` – ${booking.endTime}` : ''}`} colors={colors} />
          <View style={[styles.totalRow, { borderTopColor: colors.border }]}>
            <Text style={[styles.totalLabel, { color: colors.foreground }]}>Total</Text>
            <Text style={[styles.totalValue, { color: colors.primary }]}>${booking.totalPrice.toFixed(2)}</Text>
          </View>
        </View>

        {booking.notes && (
          <View style={[styles.notesCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
            <Text style={[styles.notesTitle, { color: colors.foreground }]}>Notes</Text>
            <Text style={[styles.notesText, { color: colors.mutedForeground }]}>{booking.notes}</Text>
          </View>
        )}

        {canCancel && (
          <TouchableOpacity
            style={[styles.cancelBtn, { borderColor: '#ef4444', borderRadius: colors.radius }]}
            onPress={handleCancel}
            disabled={updateStatus.isPending}
          >
            <Text style={styles.cancelBtnText}>
              {updateStatus.isPending ? 'Cancelling...' : 'Cancel Booking'}
            </Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </View>
  );
}

function DetailRow({ icon, label, value, colors }: { icon: string; label: string; value: string; colors: ReturnType<typeof useColors> }) {
  return (
    <View style={styles.detailRow}>
      <View style={styles.detailLeft}>
        <Feather name={icon as any} size={16} color={colors.mutedForeground} />
        <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>{label}</Text>
      </View>
      <Text style={[styles.detailValue, { color: colors.foreground }]} numberOfLines={2}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 14, borderBottomWidth: 1 },
  headerTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  content: { padding: 16, gap: 16, paddingBottom: 40 },
  statusCard: { padding: 16 },
  statusRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  statusLabel: { fontSize: 14, fontFamily: 'Inter_400Regular' },
  bookingId: { fontSize: 13, fontFamily: 'Inter_400Regular' },
  detailCard: { padding: 16 },
  detailRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', paddingVertical: 12, borderBottomWidth: 0.5 },
  detailLeft: { flexDirection: 'row', alignItems: 'center', gap: 8, flex: 1 },
  detailLabel: { fontSize: 14, fontFamily: 'Inter_400Regular' },
  detailValue: { fontSize: 14, fontFamily: 'Inter_600SemiBold', flex: 1, textAlign: 'right' },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingTop: 16, marginTop: 4, borderTopWidth: 1 },
  totalLabel: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
  totalValue: { fontSize: 22, fontFamily: 'Inter_700Bold' },
  notesCard: { padding: 16 },
  notesTitle: { fontSize: 15, fontFamily: 'Inter_600SemiBold', marginBottom: 8 },
  notesText: { fontSize: 14, fontFamily: 'Inter_400Regular', lineHeight: 22 },
  cancelBtn: { borderWidth: 1.5, padding: 16, alignItems: 'center', marginTop: 8 },
  cancelBtnText: { color: '#ef4444', fontSize: 15, fontFamily: 'Inter_600SemiBold' },
});
