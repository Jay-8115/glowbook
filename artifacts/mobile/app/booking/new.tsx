import React, { useState, useCallback } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity, ScrollView,
  Platform, FlatList,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import {
  useGetSalon, useGetSalonAvailability, useCreateBooking,
  getGetBookingsQueryKey,
} from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import * as Haptics from 'expo-haptics';

const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const DAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

function formatDate(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

function getNext14Days() {
  return Array.from({ length: 14 }, (_, i) => {
    const d = new Date(); d.setDate(d.getDate() + i); return d;
  });
}

export default function NewBookingScreen() {
  const { salonId: rawSalonId } = useLocalSearchParams<{ salonId: string }>();
  const salonId = parseInt(rawSalonId ?? '0', 10);
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const queryClient = useQueryClient();

  const [step, setStep] = useState<1|2|3>(1);
  const [selectedService, setSelectedService] = useState<number | null>(null);
  const [selectedStaff, setSelectedStaff] = useState<number | null>(null);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedTime, setSelectedTime] = useState<string | null>(null);
  const [notes, setNotes] = useState('');

  const { data: salon, isLoading: loadingSalon } = useGetSalon(salonId, { query: { enabled: !!salonId } });
  const dateStr = formatDate(selectedDate);
  const { data: slots, isLoading: loadingSlots } = useGetSalonAvailability(
    salonId,
    { date: dateStr, serviceId: selectedService ?? undefined },
    { query: { enabled: !!salonId && step === 2 } }
  );

  const createBooking = useCreateBooking();

  const selectedServiceObj = salon?.services?.find((s) => s.id === selectedService);
  const topInset = Platform.OS === 'web' ? Math.max(insets.top, 67) : insets.top;

  const handleConfirm = useCallback(async () => {
    if (!selectedService || !selectedTime) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      await createBooking.mutateAsync({
        data: {
          salonId,
          serviceId: selectedService,
          staffId: selectedStaff,
          bookingDate: dateStr,
          startTime: selectedTime,
          notes: notes || null,
        }
      });
      queryClient.invalidateQueries({ queryKey: getGetBookingsQueryKey() });
      router.replace('/(tabs)/bookings');
    } catch {
      // error handled by mutation
    }
  }, [selectedService, selectedTime, selectedStaff, dateStr, notes, salonId, createBooking, queryClient]);

  const days = getNext14Days();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Header */}
      <View style={[styles.header, { paddingTop: topInset, backgroundColor: colors.background, borderBottomColor: colors.border }]}>
        <TouchableOpacity onPress={() => step === 1 ? router.back() : setStep((s) => (s - 1) as 1|2|3)}>
          <Feather name="arrow-left" size={22} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>
          {step === 1 ? 'Select Service' : step === 2 ? 'Choose Time' : 'Confirm Booking'}
        </Text>
        <View style={{ width: 22 }} />
      </View>

      {/* Step Indicator */}
      <View style={styles.stepRow}>
        {[1,2,3].map((s) => (
          <View key={s} style={[styles.stepDot, { backgroundColor: s <= step ? colors.primary : colors.muted }]} />
        ))}
      </View>

      {loadingSalon ? (
        <View style={{ padding: 16 }}>
          {Array(4).fill(0).map((_, i) => <LoadingSkeleton key={i} width="100%" height={80} style={{ marginBottom: 12 }} />)}
        </View>
      ) : step === 1 ? (
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <Text style={[styles.stepLabel, { color: colors.mutedForeground }]}>Choose a service</Text>
          {salon?.services?.map((service) => (
            <TouchableOpacity
              key={service.id}
              style={[styles.serviceItem, {
                backgroundColor: selectedService === service.id ? colors.primary + '20' : colors.card,
                borderColor: selectedService === service.id ? colors.primary : colors.border,
                borderRadius: colors.radius,
              }]}
              onPress={() => { setSelectedService(service.id); Haptics.selectionAsync(); }}
              activeOpacity={0.8}
            >
              <View style={{ flex: 1 }}>
                <Text style={[styles.serviceName, { color: colors.foreground }]}>{service.name}</Text>
                <Text style={[styles.serviceDuration, { color: colors.mutedForeground }]}>{service.durationMinutes} min</Text>
              </View>
              <View style={styles.servicePriceRow}>
                <Text style={[styles.servicePrice, { color: colors.primary }]}>${service.price.toFixed(0)}</Text>
                {selectedService === service.id && (
                  <Feather name="check-circle" size={20} color={colors.primary} style={{ marginLeft: 8 }} />
                )}
              </View>
            </TouchableOpacity>
          ))}
        </ScrollView>
      ) : step === 2 ? (
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <Text style={[styles.stepLabel, { color: colors.mutedForeground }]}>Pick a date</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.datesRow}>
            {days.map((day, i) => {
              const isSelected = formatDate(day) === dateStr;
              return (
                <TouchableOpacity
                  key={i}
                  style={[styles.dayPill, {
                    backgroundColor: isSelected ? colors.primary : colors.card,
                    borderColor: isSelected ? colors.primary : colors.border,
                    borderRadius: 12,
                  }]}
                  onPress={() => { setSelectedDate(day); setSelectedTime(null); Haptics.selectionAsync(); }}
                >
                  <Text style={[styles.dayName, { color: isSelected ? colors.primaryForeground : colors.mutedForeground }]}>
                    {DAYS[day.getDay()]}
                  </Text>
                  <Text style={[styles.dayNum, { color: isSelected ? colors.primaryForeground : colors.foreground }]}>
                    {day.getDate()}
                  </Text>
                  <Text style={[styles.dayMonth, { color: isSelected ? colors.primaryForeground : colors.mutedForeground }]}>
                    {MONTHS[day.getMonth()]}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>

          <Text style={[styles.stepLabel, { color: colors.mutedForeground, marginTop: 24 }]}>Pick a time</Text>
          {loadingSlots ? (
            <View style={styles.slotsGrid}>
              {Array(8).fill(0).map((_, i) => <LoadingSkeleton key={i} width={85} height={44} borderRadius={8} />)}
            </View>
          ) : (
            <View style={styles.slotsGrid}>
              {slots?.filter((s) => s.available).map((slot) => (
                <TouchableOpacity
                  key={slot.time}
                  style={[styles.slotPill, {
                    backgroundColor: selectedTime === slot.time ? colors.primary : colors.card,
                    borderColor: selectedTime === slot.time ? colors.primary : colors.border,
                    borderRadius: 8,
                  }]}
                  onPress={() => { setSelectedTime(slot.time); Haptics.selectionAsync(); }}
                >
                  <Text style={{ color: selectedTime === slot.time ? colors.primaryForeground : colors.foreground, fontFamily: 'Inter_500Medium', fontSize: 14 }}>
                    {slot.time}
                  </Text>
                </TouchableOpacity>
              ))}
              {!loadingSlots && !slots?.filter((s) => s.available).length && (
                <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>No available slots for this date</Text>
              )}
            </View>
          )}

          {/* Optional Staff Selection */}
          {salon?.staff && salon.staff.length > 0 && (
            <>
              <Text style={[styles.stepLabel, { color: colors.mutedForeground, marginTop: 24 }]}>Preferred stylist (optional)</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 12, paddingVertical: 8 }}>
                <TouchableOpacity
                  style={[styles.staffPill, { backgroundColor: !selectedStaff ? colors.primary + '20' : colors.card, borderColor: !selectedStaff ? colors.primary : colors.border, borderRadius: 24 }]}
                  onPress={() => setSelectedStaff(null)}
                >
                  <Text style={[styles.staffName, { color: !selectedStaff ? colors.primary : colors.foreground }]}>Any</Text>
                </TouchableOpacity>
                {salon.staff.map((m) => (
                  <TouchableOpacity
                    key={m.id}
                    style={[styles.staffPill, { backgroundColor: selectedStaff === m.id ? colors.primary + '20' : colors.card, borderColor: selectedStaff === m.id ? colors.primary : colors.border, borderRadius: 24 }]}
                    onPress={() => setSelectedStaff(m.id)}
                  >
                    <Text style={[styles.staffName, { color: selectedStaff === m.id ? colors.primary : colors.foreground }]}>{m.name}</Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </>
          )}
        </ScrollView>
      ) : (
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <Text style={[styles.stepLabel, { color: colors.mutedForeground }]}>Booking summary</Text>
          <View style={[styles.summaryCard, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
            <Row label="Salon" value={salon?.name ?? ''} colors={colors} />
            <Row label="Service" value={selectedServiceObj?.name ?? ''} colors={colors} />
            <Row label="Duration" value={`${selectedServiceObj?.durationMinutes ?? 0} min`} colors={colors} />
            <Row label="Date" value={dateStr} colors={colors} />
            <Row label="Time" value={selectedTime ?? ''} colors={colors} />
            {selectedStaff && (
              <Row label="Stylist" value={salon?.staff?.find((s) => s.id === selectedStaff)?.name ?? ''} colors={colors} />
            )}
            <View style={[styles.totalRow, { borderTopColor: colors.border }]}>
              <Text style={[styles.totalLabel, { color: colors.foreground }]}>Total</Text>
              <Text style={[styles.totalValue, { color: colors.primary }]}>${selectedServiceObj?.price.toFixed(2)}</Text>
            </View>
          </View>
        </ScrollView>
      )}

      {/* Bottom CTA */}
      <View style={[styles.footer, { paddingBottom: insets.bottom + 16, borderTopColor: colors.border, backgroundColor: colors.background }]}>
        <TouchableOpacity
          style={[styles.ctaBtn, {
            backgroundColor: (step === 1 && !selectedService) || (step === 2 && !selectedTime) ? colors.muted : colors.primary,
            borderRadius: colors.radius,
          }]}
          disabled={(step === 1 && !selectedService) || (step === 2 && !selectedTime) || createBooking.isPending}
          onPress={() => {
            if (step < 3) { setStep((s) => (s + 1) as 1|2|3); }
            else { handleConfirm(); }
          }}
          activeOpacity={0.85}
        >
          <Text style={[styles.ctaBtnText, { color: colors.primaryForeground }]}>
            {step < 3 ? 'Continue' : createBooking.isPending ? 'Booking...' : 'Confirm Booking'}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

function Row({ label, value, colors }: { label: string; value: string; colors: ReturnType<typeof useColors> }) {
  return (
    <View style={styles.summaryRow}>
      <Text style={[styles.summaryLabel, { color: colors.mutedForeground }]}>{label}</Text>
      <Text style={[styles.summaryValue, { color: colors.foreground }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 14, borderBottomWidth: 1 },
  headerTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  stepRow: { flexDirection: 'row', justifyContent: 'center', gap: 8, paddingVertical: 12 },
  stepDot: { width: 32, height: 4, borderRadius: 2 },
  scrollContent: { padding: 16, paddingBottom: 80 },
  stepLabel: { fontSize: 13, fontFamily: 'Inter_500Medium', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 0.5 },
  serviceItem: { flexDirection: 'row', alignItems: 'center', padding: 16, marginBottom: 12, borderWidth: 1.5 },
  serviceName: { fontSize: 16, fontFamily: 'Inter_600SemiBold', marginBottom: 4 },
  serviceDuration: { fontSize: 13, fontFamily: 'Inter_400Regular' },
  servicePriceRow: { flexDirection: 'row', alignItems: 'center' },
  servicePrice: { fontSize: 18, fontFamily: 'Inter_700Bold' },
  datesRow: { gap: 10, paddingBottom: 8 },
  dayPill: { width: 64, alignItems: 'center', paddingVertical: 12, borderWidth: 1.5 },
  dayName: { fontSize: 11, fontFamily: 'Inter_500Medium', marginBottom: 4 },
  dayNum: { fontSize: 22, fontFamily: 'Inter_700Bold', lineHeight: 26 },
  dayMonth: { fontSize: 10, fontFamily: 'Inter_400Regular', marginTop: 2 },
  slotsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  slotPill: { paddingHorizontal: 16, paddingVertical: 12, borderWidth: 1.5, alignItems: 'center', minWidth: 85 },
  staffPill: { paddingHorizontal: 20, paddingVertical: 10, borderWidth: 1.5 },
  staffName: { fontSize: 14, fontFamily: 'Inter_500Medium' },
  summaryCard: { padding: 20 },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
  summaryLabel: { fontSize: 14, fontFamily: 'Inter_400Regular' },
  summaryValue: { fontSize: 14, fontFamily: 'Inter_600SemiBold' },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, paddingTop: 16, marginTop: 4 },
  totalLabel: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
  totalValue: { fontSize: 22, fontFamily: 'Inter_700Bold' },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', paddingVertical: 8 },
  footer: { paddingHorizontal: 16, paddingTop: 16, borderTopWidth: 1 },
  ctaBtn: { height: 52, alignItems: 'center', justifyContent: 'center' },
  ctaBtnText: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
});
