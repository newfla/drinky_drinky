/// Biological sex options for the hydration recommendation calculator.
/// These are stable domain identifiers used as map keys.
/// NEVER use display strings as map keys -- that caused the locale crash this enum fixes.
enum BiologicalSex { male, female, other }

/// Climate level options for the hydration recommendation calculator.
/// Index 0=cold, 1=mild, 2=warm, 3=veryWarm, 4=humid -- must match _climateMultipliers order.
enum ClimateLevel { cold, mild, warm, veryWarm, humid }
