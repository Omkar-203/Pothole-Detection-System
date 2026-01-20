import matplotlib.pyplot as plt
import matplotlib.patches as patches

# System Architecture Diagram
fig, ax = plt.subplots(figsize=(10, 6))
ax.set_xlim(0, 10)
ax.set_ylim(0, 6)
ax.axis('off')

# Components
components = [
    {'name': 'Mobile App\n(Flutter)', 'pos': (1, 4), 'size': (2, 1)},
    {'name': 'REST API\n(FastAPI)', 'pos': (4.5, 4), 'size': (2, 1)},
    {'name': 'Inference Service\n(YOLOv8)', 'pos': (4.5, 2), 'size': (2, 1)},
    {'name': 'Database\n(SQLAlchemy)', 'pos': (7, 4), 'size': (2, 1)},
    {'name': 'Storage\n(Uploads)', 'pos': (7, 2), 'size': (2, 1)},
]

for comp in components:
    rect = patches.FancyBboxPatch((comp['pos'][0], comp['pos'][1]), comp['size'][0], comp['size'][1],
                                  boxstyle="round,pad=0.1", facecolor='lightblue', edgecolor='black')
    ax.add_patch(rect)
    ax.text(comp['pos'][0] + comp['size'][0]/2, comp['pos'][1] + comp['size'][1]/2, comp['name'],
            ha='center', va='center', fontsize=10)

# Arrows
ax.arrow(3, 4.5, 1, 0, head_width=0.1, head_length=0.1, fc='black', ec='black')
ax.arrow(6.5, 4.5, 0, -1.5, head_width=0.1, head_length=0.1, fc='black', ec='black')
ax.arrow(6.5, 3, 0, -0.5, head_width=0.1, head_length=0.1, fc='black', ec='black')
ax.arrow(4.5, 3, -1, 0, head_width=0.1, head_length=0.1, fc='black', ec='black')

plt.title('System Architecture Diagram')
plt.savefig('system_architecture.png', dpi=300, bbox_inches='tight')
# plt.show()