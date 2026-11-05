String nearbyDistanceLabel(String band) => switch (band) {
  'under_5_km' => 'أقل من 5 كم',
  '5_15_km' => '5–15 كم',
  '15_25_km' => '15–25 كم',
  _ => 'مسافة تقريبية',
};
