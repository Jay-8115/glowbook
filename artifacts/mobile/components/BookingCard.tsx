import React from 'react';
import { View, Text, StyleSheet, Pressable, TouchableOpacity } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { StatusBadge } from './StatusBadge';
import { router } from 'expo-router';

interface BookingType {
  id: number;
  status: string;
  bookingDate: string;
  startTime: string;
  totalPrice: number;
  user?: { name: string } | null;
  salon?: { name: string } | null;
  service?: { name: string } | null;
  staff?: { name: string } | null;
}

interface BookingCardProps {
  booking: BookingType;
  isOwnerView?: boolean;
  onStatusChange?: (bookingId: number, status: string) => void;
}

const STATUS_ACTIONS: Record<string, { label: string; nextStatus: string; color: string }[]> = {
  pending: [
    { label: 'Accept', nextStatus: 'accepted', color: '#22c55e' },
    { label: 'Decline', nextStatus: 'cancelled', color: '#ef4444' },
  ],
  accepted: [
    { label: 'Start', nextStatus: 'in_progress', color: '#3b82f6' },
  ],
  in_progress: [
    { label: 'Complete', nextStatus: 'completed', color: '#22c55e' },
  ],
};

export function BookingCard({ booking, isOwnerView = false, onStatusChange }: BookingCardProps) {
  const colors = useColors();

  const formattedDate = (() => {
    try {
      return new Date(booking.bookingDate).toLocaleDateString('en-US', {
        weekday: 'short', month: 'short', day: 'numeric',
      });
    } catch {
      return booking.bookingDate;
    }
  })();

  const actions = isOwnerView ? STATUS_ACTIONS[booking.status] ?? [] : [];

  return (
    <Pressable
      style={[styles.card, { backgroundColor: colors.card, borderRadius: colors.radius, borderColor: colors.border }]}
      onPress={() => router.push(`/booking/${booking.id}` as any)}
    >
      <View style={styles.header}>
        <Text style={[styles.title, { color: colors.cardForeground }]} numberOfLines={1}>
          {isOwnerView ? (booking.user?.name ?? 'Customer') : (booking.salon?.name ?? 'Salon')}
        </Text>
        <StatusBadge status={booking.status} />
      </View>

      <View style={styles.details}>
        <Text style={[styles.serviceName, { color: colors.foreground }]} numberOfLines={1}>
          {booking.service?.name ?? 'Service'}
        </Text>
        <Text style={[styles.price, { color: colors.primary }]}>
          ${booking.totalPrice.toFixed(2)}
        </Text>
      </View>

      <View style={[styles.divider, { backgroundColor: colors.border }]} />

      <View style={styles.footer}>
        <View style={styles.timeInfo}>
          <Feather name="calendar" size={14} color={colors.mutedForeground} />
          <Text style={[styles.timeText, { color: colors.mutedForeground }]}>
            {formattedDate} • {booking.startTime}
          </Text>
        </View>
        {booking.staff && (
          <View style={styles.staffInfo}>
            <Feather name="scissors" size={14} color={colors.mutedForeground} />
            <Text style={[styles.staffText, { color: colors.mutedForeground }]}>
              {booking.staff.name}
            </Text>
          </View>
        )}
      </View>

      {actions.length > 0 && onStatusChange && (
        <View style={styles.actionsRow}>
          {actions.map((action) => (
            <TouchableOpacity
              key={action.nextStatus}
              style={[styles.actionBtn, { backgroundColor: action.color + '15', borderColor: action.color, borderRadius: 8 }]}
              onPress={(e) => { e.stopPropagation?.(); onStatusChange(booking.id, action.nextStatus); }}
            >
              <Text style={[styles.actionText, { color: action.color }]}>{action.label}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { padding: 16, borderWidth: 1, marginBottom: 12 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12, gap: 16 },
  title: { fontSize: 16, fontFamily: 'Inter_600SemiBold', flex: 1 },
  details: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  serviceName: { fontSize: 15, fontFamily: 'Inter_500Medium', flex: 1 },
  price: { fontSize: 15, fontFamily: 'Inter_700Bold' },
  divider: { height: 1, width: '100%', marginBottom: 12 },
  footer: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  timeInfo: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  timeText: { fontSize: 13, fontFamily: 'Inter_500Medium' },
  staffInfo: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  staffText: { fontSize: 13, fontFamily: 'Inter_400Regular' },
  actionsRow: { flexDirection: 'row', gap: 8, marginTop: 12 },
  actionBtn: { flex: 1, paddingVertical: 8, alignItems: 'center', borderWidth: 1 },
  actionText: { fontSize: 13, fontFamily: 'Inter_600SemiBold' },
});
