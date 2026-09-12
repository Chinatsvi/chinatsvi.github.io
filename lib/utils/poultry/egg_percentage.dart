double calculateEggPercentage({
  required int eggsCollected,
  required int liveBirds,
}) {
  if (liveBirds == 0) return 0;
  return (eggsCollected / liveBirds) * 100;
}
