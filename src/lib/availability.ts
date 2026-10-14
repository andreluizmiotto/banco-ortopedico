export type EquipmentType = {
  code: string;
  name: string;
  display_order: number;
};

export type BankAvailability = {
  bank_name: string;
  available_quantity: number;
};

export function orderAvailability(
  rows: readonly BankAvailability[],
  random: () => number = Math.random,
): BankAvailability[] {
  const available: BankAvailability[] = [];
  const unavailable: BankAvailability[] = [];

  for (const row of rows) {
    if (row.available_quantity > 0) {
      available.push(row);
    } else {
      unavailable.push(row);
    }
  }

  for (let index = available.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [available[index], available[swapIndex]] = [
      available[swapIndex],
      available[index],
    ];
  }

  return [...available, ...unavailable];
}
