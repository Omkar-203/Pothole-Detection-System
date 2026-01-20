import pandas as pd
import matplotlib.pyplot as plt

# Load the results.csv
df = pd.read_csv('working/runs/yolov8m_pothole_train/results.csv')

# Plot training and validation loss
plt.figure(figsize=(10, 5))

plt.subplot(1, 2, 1)
plt.plot(df['epoch'], df['train/box_loss'], label='Train Box Loss')
plt.plot(df['epoch'], df['val/box_loss'], label='Val Box Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.title('Training and Validation Box Loss')
plt.legend()

plt.subplot(1, 2, 2)
plt.plot(df['epoch'], df['metrics/mAP50(B)'], label='mAP50')
plt.plot(df['epoch'], df['metrics/mAP50-95(B)'], label='mAP50-95')
plt.xlabel('Epoch')
plt.ylabel('mAP')
plt.title('Validation mAP over Epochs')
plt.legend()

plt.tight_layout()
plt.savefig('training_curves.png', dpi=300)
plt.show()