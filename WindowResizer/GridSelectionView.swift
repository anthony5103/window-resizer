import SwiftUI

struct GridSelectionView: View {
    @Binding var gridConfig: GridConfiguration
    @State private var selectedCells: Set<GridCell> = []
    @State private var isDragging = false
    @State private var dragStartCell: GridCell?
    @State private var hoveredCell: GridCell? = nil
    @State private var localRows: Int
    @State private var localColumns: Int
    let onResize: (Set<GridCell>) -> Void

    init(gridConfig: Binding<GridConfiguration>, onResize: @escaping (Set<GridCell>) -> Void) {
        self._gridConfig = gridConfig
        self.onResize = onResize
        _localRows = State(initialValue: gridConfig.wrappedValue.rows)
        _localColumns = State(initialValue: gridConfig.wrappedValue.columns)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Grid configuration controls
            HStack {
                Text("Grid:")
                Stepper(
                    value: Binding(
                        get: { localRows },
                        set: { newValue in
                            // Update immediately for instant UI feedback
                            localRows = newValue
                            gridConfig.rows = newValue
                            selectedCells.removeAll()  // Clear selection when grid changes
                        }
                    ), in: 1...8
                ) {
                    Text("Rows: \(localRows)")
                }
                Stepper(
                    value: Binding(
                        get: { localColumns },
                        set: { newValue in
                            // Update immediately for instant UI feedback
                            localColumns = newValue
                            gridConfig.columns = newValue
                            selectedCells.removeAll()  // Clear selection when grid changes
                        }
                    ), in: 1...8
                ) {
                    Text("Columns: \(localColumns)")
                }
            }
            .padding(.horizontal)
            .padding(.top)
            // Sync external changes (from menu) back to local state
            .onChange(of: gridConfig.rows) { newValue in
                if localRows != newValue {
                    localRows = newValue
                }
            }
            .onChange(of: gridConfig.columns) { newValue in
                if localColumns != newValue {
                    localColumns = newValue
                }
            }

            Divider()

            // Grid display
            GeometryReader { geometry in
                let cellWidth = geometry.size.width / CGFloat(localColumns)
                let cellHeight = geometry.size.height / CGFloat(localRows)

                ZStack {
                    // Grid cells
                    ForEach(0..<localRows, id: \.self) { row in
                        ForEach(0..<localColumns, id: \.self) { col in
                            let cell = GridCell(row: row, column: col)
                            let isSelected = selectedCells.contains(cell)
                            let isHovered = hoveredCell == cell && !isDragging

                            Rectangle()
                                .fill(
                                    isSelected
                                        ? Color.accentColor.opacity(0.7)
                                        : (isHovered
                                            ? Color.accentColor.opacity(0.3)
                                            : Color.gray.opacity(0.1))
                                )
                                .border(
                                    isSelected
                                        ? Color.accentColor
                                        : Color.gray.opacity(0.3),
                                    width: isSelected ? 2 : 1
                                )
                                .frame(width: cellWidth, height: cellHeight)
                                .position(
                                    x: CGFloat(col) * cellWidth + cellWidth / 2,
                                    y: CGFloat(row) * cellHeight + cellHeight / 2
                                )
                        }
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        if !isDragging {
                            let col = min(max(Int(location.x / cellWidth), 0), localColumns - 1)
                            let row = min(max(Int(location.y / cellHeight), 0), localRows - 1)
                            hoveredCell = GridCell(row: row, column: col)
                        }
                    case .ended:
                        hoveredCell = nil
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let col = min(
                                max(Int(value.location.x / cellWidth), 0), localColumns - 1)
                            let row = min(max(Int(value.location.y / cellHeight), 0), localRows - 1)
                            let currentCell = GridCell(row: row, column: col)

                            hoveredCell = nil  // Clear hover during drag

                            if !isDragging {
                                isDragging = true
                                dragStartCell = currentCell
                                selectedCells = [currentCell]
                            } else if let startCell = dragStartCell {
                                selectedCells = getCellsBetween(startCell, currentCell)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragStartCell = nil
                        }
                )
                .onTapGesture { location in
                    let col = min(max(Int(location.x / cellWidth), 0), localColumns - 1)
                    let row = min(max(Int(location.y / cellHeight), 0), localRows - 1)
                    selectedCells = [GridCell(row: row, column: col)]
                }
            }
            .frame(height: 300)
            .padding()

            Divider()

            // Action button
            Button(action: {
                guard !selectedCells.isEmpty else { return }
                onResize(selectedCells)
            }) {
                Text("Resize Window")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCells.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 400, height: 450)
    }

    func getCellsBetween(_ start: GridCell, _ end: GridCell) -> Set<GridCell> {
        var cells = Set<GridCell>()
        let minRow = min(start.row, end.row)
        let maxRow = max(start.row, end.row)
        let minCol = min(start.column, end.column)
        let maxCol = max(start.column, end.column)

        for row in minRow...maxRow {
            for col in minCol...maxCol {
                cells.insert(GridCell(row: row, column: col))
            }
        }

        return cells
    }
}
