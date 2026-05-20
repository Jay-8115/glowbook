import React, { useCallback } from 'react';
import {
  StyleSheet, View, Text, ScrollView, TouchableOpacity,
  Platform, Animated, Dimensions, FlatList,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Image } from 'expo-image';
import { Feather, Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import {
  useGetSalon, useAddFavorite, useRemoveFavorite,
  useGetSalonReviews, getGetFavoritesQueryKey, getGetSalonQueryKey,
} from '@workspace/api-client-react';
import { useQueryClient } from '@tanstack/react-query';
import { RatingStars } from '@/components/RatingStars';
import { ServiceCard } from '@/components/ServiceCard';
import { StaffChip } from '@/components/StaffChip';
import { ReviewCard } from '@/components/ReviewCard';
import { LoadingSkeleton } from '@/components/LoadingSkeleton';
import * as Haptics from 'expo-haptics';
import { useAuth } from '@/context/AuthContext';

const { width, height } = Dimensions.get('window');
const HERO_HEIGHT = 320;

export default function SalonDetailScreen() {
  const { id: rawId } = useLocalSearchParams<{ id: string }>();
  const id = parseInt(rawId ?? '0', 10);
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const queryClient = useQueryClient();
  const { user } = useAuth();

  const { data: salon, isLoading } = useGetSalon(id, { query: { enabled: !!id } });
  const { data: reviewsData } = useGetSalonReviews(id, undefined, { query: { enabled: !!id } });

  const addFav = useAddFavorite();
  const removeFav = useRemoveFavorite();

  const scrollY = React.useRef(new Animated.Value(0)).current;
  const headerOpacity = scrollY.interpolate({ inputRange: [200, 280], outputRange: [0, 1], extrapolate: 'clamp' });

  const handleFavorite = useCallback(async () => {
    if (!user) { router.push('/auth/login'); return; }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (salon?.isFavorited) {
      await removeFav.mutateAsync({ salonId: id });
    } else {
      await addFav.mutateAsync({ salonId: id });
    }
    queryClient.invalidateQueries({ queryKey: getGetSalonQueryKey(id) });
    queryClient.invalidateQueries({ queryKey: getGetFavoritesQueryKey() });
  }, [salon?.isFavorited, id, user, addFav, removeFav, queryClient]);

  const handleBook = useCallback(() => {
    if (!user) { router.push('/auth/login'); return; }
    router.push({ pathname: '/booking/new', params: { salonId: id } });
  }, [id, user]);

  if (isLoading || !salon) {
    return (
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        <LoadingSkeleton width={width} height={HERO_HEIGHT} />
        <View style={{ padding: 16 }}>
          <LoadingSkeleton width={200} height={28} style={{ marginBottom: 12 }} />
          <LoadingSkeleton width={150} height={20} style={{ marginBottom: 8 }} />
          <LoadingSkeleton width={width - 32} height={16} style={{ marginBottom: 8 }} />
        </View>
      </View>
    );
  }

  const images = salon.images?.length ? salon.images : [salon.imageUrl].filter(Boolean);

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Animated Header */}
      <Animated.View style={[styles.animatedHeader, { paddingTop: insets.top, opacity: headerOpacity, backgroundColor: colors.background }]}>
        <Text style={[styles.headerTitle, { color: colors.foreground }]} numberOfLines={1}>{salon.name}</Text>
      </Animated.View>

      {/* Back + Favorite buttons */}
      <View style={[styles.overlayButtons, { top: insets.top + (Platform.OS === 'web' ? 67 : 0) }]}>
        <TouchableOpacity style={[styles.iconBtn, { backgroundColor: 'rgba(0,0,0,0.5)' }]} onPress={() => router.back()}>
          <Feather name="arrow-left" size={20} color="#fff" />
        </TouchableOpacity>
        <TouchableOpacity style={[styles.iconBtn, { backgroundColor: 'rgba(0,0,0,0.5)' }]} onPress={handleFavorite}>
          <Ionicons name={salon.isFavorited ? 'heart' : 'heart-outline'} size={20} color={salon.isFavorited ? '#ef4444' : '#fff'} />
        </TouchableOpacity>
      </View>

      <Animated.ScrollView
        showsVerticalScrollIndicator={false}
        onScroll={Animated.event([{ nativeEvent: { contentOffset: { y: scrollY } } }], { useNativeDriver: Platform.OS !== 'web' })}
        scrollEventThrottle={16}
        contentContainerStyle={{ paddingBottom: 120 + insets.bottom }}
      >
        {/* Hero Image */}
        {images.length > 0 ? (
          <Image
            source={{ uri: images[0] }}
            style={styles.heroImage}
            contentFit="cover"
          />
        ) : (
          <View style={[styles.heroImage, styles.heroPlaceholder, { backgroundColor: colors.card }]}>
            <MaterialCommunityIcons name="scissors-cutting" size={60} color={colors.primary} />
          </View>
        )}

        {/* Main Info */}
        <View style={styles.mainInfo}>
          <View style={styles.nameRow}>
            <Text style={[styles.salonName, { color: colors.foreground }]}>{salon.name}</Text>
            {salon.isVerified && (
              <MaterialCommunityIcons name="check-decagram" size={20} color={colors.primary} />
            )}
          </View>
          <View style={styles.ratingRow}>
            <RatingStars rating={salon.avgRating} size={16} />
            <Text style={[styles.ratingText, { color: colors.foreground }]}>{salon.avgRating.toFixed(1)}</Text>
            <Text style={[styles.reviewCount, { color: colors.mutedForeground }]}>({salon.totalReviews} reviews)</Text>
          </View>
          <View style={styles.infoRow}>
            <Feather name="map-pin" size={14} color={colors.mutedForeground} />
            <Text style={[styles.infoText, { color: colors.mutedForeground }]}>{salon.address}, {salon.city}</Text>
          </View>
          {salon.openTime && salon.closeTime && (
            <View style={styles.infoRow}>
              <Feather name="clock" size={14} color={colors.mutedForeground} />
              <Text style={[styles.infoText, { color: colors.mutedForeground }]}>{salon.openTime} – {salon.closeTime}</Text>
            </View>
          )}
          {salon.phone && (
            <View style={styles.infoRow}>
              <Feather name="phone" size={14} color={colors.mutedForeground} />
              <Text style={[styles.infoText, { color: colors.mutedForeground }]}>{salon.phone}</Text>
            </View>
          )}
          {salon.description && (
            <Text style={[styles.description, { color: colors.mutedForeground }]}>{salon.description}</Text>
          )}
        </View>

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        {/* Services */}
        {salon.services && salon.services.length > 0 && (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Services</Text>
            {salon.services.map((service) => (
              <ServiceCard key={service.id} service={service} onPress={handleBook} />
            ))}
          </View>
        )}

        {/* Staff */}
        {salon.staff && salon.staff.length > 0 && (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Our Team</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.staffRow}>
              {salon.staff.map((member) => (
                <StaffChip key={member.id} staff={member} />
              ))}
            </ScrollView>
          </View>
        )}

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        {/* Reviews */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Reviews</Text>
          {reviewsData?.reviews?.length ? (
            reviewsData.reviews.map((review) => (
              <ReviewCard key={review.id} review={review} />
            ))
          ) : (
            <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>No reviews yet. Be the first!</Text>
          )}
        </View>
      </Animated.ScrollView>

      {/* Sticky Book Button */}
      <View style={[styles.bookBar, { backgroundColor: colors.background, paddingBottom: insets.bottom + 16, borderTopColor: colors.border }]}>
        <View style={styles.priceHint}>
          {salon.services?.[0] && (
            <>
              <Text style={[styles.priceFrom, { color: colors.mutedForeground }]}>From</Text>
              <Text style={[styles.priceValue, { color: colors.primary }]}>
                ${Math.min(...salon.services.map((s) => s.price)).toFixed(0)}
              </Text>
            </>
          )}
        </View>
        <TouchableOpacity
          style={[styles.bookBtn, { backgroundColor: colors.primary, borderRadius: colors.radius }]}
          onPress={handleBook}
          activeOpacity={0.85}
        >
          <Text style={[styles.bookBtnText, { color: colors.primaryForeground }]}>Book Appointment</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  animatedHeader: {
    position: 'absolute', top: 0, left: 0, right: 0, zIndex: 20,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    paddingBottom: 12, paddingHorizontal: 16,
  },
  headerTitle: { fontSize: 18, fontFamily: 'Inter_600SemiBold' },
  overlayButtons: {
    position: 'absolute', left: 0, right: 0, zIndex: 30,
    flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 16,
  },
  iconBtn: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  heroImage: { width: '100%', height: HERO_HEIGHT },
  heroPlaceholder: { alignItems: 'center', justifyContent: 'center' },
  mainInfo: { padding: 20 },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
  salonName: { fontSize: 24, fontFamily: 'Inter_700Bold', flex: 1 },
  ratingRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 12 },
  ratingText: { fontSize: 15, fontFamily: 'Inter_600SemiBold' },
  reviewCount: { fontSize: 14, fontFamily: 'Inter_400Regular' },
  infoRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 6 },
  infoText: { fontSize: 14, fontFamily: 'Inter_400Regular', flex: 1 },
  description: { fontSize: 14, fontFamily: 'Inter_400Regular', lineHeight: 22, marginTop: 12 },
  divider: { height: 8, marginVertical: 8 },
  section: { paddingHorizontal: 20, paddingVertical: 16 },
  sectionTitle: { fontSize: 20, fontFamily: 'Inter_600SemiBold', marginBottom: 16 },
  staffRow: { paddingRight: 16, gap: 12 },
  emptyText: { fontSize: 14, fontFamily: 'Inter_400Regular', textAlign: 'center', paddingVertical: 16 },
  bookBar: {
    position: 'absolute', bottom: 0, left: 0, right: 0,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 20, paddingTop: 16, borderTopWidth: 1,
  },
  priceHint: { flexDirection: 'row', alignItems: 'baseline', gap: 4 },
  priceFrom: { fontSize: 13, fontFamily: 'Inter_400Regular' },
  priceValue: { fontSize: 22, fontFamily: 'Inter_700Bold' },
  bookBtn: { paddingHorizontal: 32, paddingVertical: 14, minWidth: 180, alignItems: 'center' },
  bookBtnText: { fontSize: 16, fontFamily: 'Inter_600SemiBold' },
});
