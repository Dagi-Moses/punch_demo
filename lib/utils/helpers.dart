List<int> calculatePageSizes(int totalItems) {
  if (totalItems < 10) {
    return [totalItems];
  } else if (totalItems < 50) {
    return [10, totalItems];
  } else if (totalItems < 100) {
    return [10, 20, totalItems];
  } else {
    return [10, 20, 50, 100];
  }
}
