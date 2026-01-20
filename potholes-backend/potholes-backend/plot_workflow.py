import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Workflow / User Journey Diagram
fig, ax = plt.subplots(figsize=(12, 8))
ax.set_xlim(0, 12)
ax.set_ylim(0, 8)
ax.axis('off')

# Steps
steps = [
    {'text': '1. Open App\nCapture Photo', 'pos': (1, 6)},
    {'text': '2. Add GPS\nLocation', 'pos': (3, 6)},
    {'text': '3. Upload to\nBackend', 'pos': (5, 6)},
    {'text': '4. Backend\nInference', 'pos': (7, 6)},
    {'text': '5. Return Results\n(Severity, Depth)', 'pos': (9, 6)},
    {'text': '6. Display on Map\n& Submit Report', 'pos': (5, 4)},
]

for step in steps:
    circle = patches.Circle((step['pos'][0], step['pos'][1]), 0.8, facecolor='lightgreen', edgecolor='black')
    ax.add_patch(circle)
    ax.text(step['pos'][0], step['pos'][1], step['text'], ha='center', va='center', fontsize=9)

# Arrows
for i in range(len(steps)-1):
    x1, y1 = steps[i]['pos']
    x2, y2 = steps[i+1]['pos']
    ax.arrow(x1 + 0.8, y1, x2 - x1 - 1.6, 0, head_width=0.1, head_length=0.1, fc='black', ec='black')

# Arrow to display
ax.arrow(9, 5.2, -3, -1, head_width=0.1, head_length=0.1, fc='black', ec='black')

plt.title('User Journey Workflow Diagram')
plt.savefig('user_journey.png', dpi=300, bbox_inches='tight')
# plt.show()