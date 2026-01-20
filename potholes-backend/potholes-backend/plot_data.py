import os
import matplotlib.pyplot as plt
from collections import defaultdict
import random
from PIL import Image

# Function to count classes in a directory
def count_classes(label_dir):
    class_counts = defaultdict(int)
    for file in os.listdir(label_dir):
        if file.endswith('.txt'):
            with open(os.path.join(label_dir, 'labels', file), 'r') as f:
                for line in f:
                    cls = int(line.split()[0])
                    class_counts[cls] += 1
    return class_counts

# Count in train, val, test
train_counts = count_classes('working/train')
val_counts = count_classes('working/val')
test_counts = count_classes('working/test')

# Combine
total_counts = defaultdict(int)
for d in [train_counts, val_counts, test_counts]:
    for cls, count in d.items():
        total_counts[cls] += count

# Class names
class_names = ['minor_pothole', 'medium_pothole', 'major_pothole']

# Plot class distribution
plt.figure(figsize=(8, 6))
plt.bar(class_names, [total_counts[i] for i in range(3)])
plt.xlabel('Class')
plt.ylabel('Number of Instances')
plt.title('Dataset Class Distribution')
plt.savefig('class_distribution.png', dpi=300)
# plt.show()

# Sample images grid
fig, axes = plt.subplots(3, 3, figsize=(12, 12))
image_dir = 'working/train/images'
label_dir = 'working/train/labels'

images = [f for f in os.listdir(image_dir) if f.endswith('.jpg')][:9]

for i, img_file in enumerate(images):
    img_path = os.path.join(image_dir, img_file)
    img = Image.open(img_path)
    ax = axes[i//3, i%3]
    ax.imshow(img)
    ax.axis('off')
    # Add bounding boxes if labels exist
    label_file = img_file.replace('.jpg', '.txt')
    label_path = os.path.join(label_dir, label_file)
    if os.path.exists(label_path):
        with open(label_path, 'r') as f:
            for line in f:
                parts = line.split()
                cls = int(parts[0])
                x, y, w, h = map(float, parts[1:])
                # Convert to pixel coords (assuming 640x640)
                img_w, img_h = img.size
                x1 = (x - w/2) * img_w
                y1 = (y - h/2) * img_h
                x2 = (x + w/2) * img_w
                y2 = (y + h/2) * img_h
                rect = plt.Rectangle((x1, y1), x2-x1, y2-y1, linewidth=2, edgecolor='red', facecolor='none')
                ax.add_patch(rect)
                ax.text(x1, y1, class_names[cls], color='red', fontsize=8)

plt.tight_layout()
plt.savefig('sample_images.png', dpi=300)
# plt.show()