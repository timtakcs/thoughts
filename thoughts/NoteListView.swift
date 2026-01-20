//
//  NoteListView.swift
//  thoughts
//
//  Created by Timur Takhtarov on 12/18/25.
//

import SwiftUI
import UIKit

struct NoteListView: UIViewRepresentable {
    let notes: [Note]
    let onNoteTap: (Note) -> Void
    let onNoteDelete: (Note) -> Void
    
    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .appBackground
        tableView.separatorStyle = .none
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.register(NoteCell.self, forCellReuseIdentifier: "NoteCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.delaysContentTouches = false

        context.coordinator.scrollIndicator = ScrollIndicator(scrollView: tableView)

        return tableView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) {
        let oldNotes = context.coordinator.notes
        let newNotes = notes

        context.coordinator.onNoteTap = onNoteTap
        context.coordinator.onNoteDelete = onNoteDelete

        // at the start the coordinator notes are empty
        // we need to load the notes from the component
        // to ensure that they are correctly populated
        if oldNotes.isEmpty && !newNotes.isEmpty {
            context.coordinator.notes = newNotes
            uiView.reloadData()
            return
        }

        let changes = calculateChanges(from: oldNotes, to: newNotes)

        if !changes.deletions.isEmpty || !changes.insertions.isEmpty {
            uiView.performBatchUpdates {
                if !changes.deletions.isEmpty {
                    uiView.deleteRows(at: changes.deletions, with: .fade)
                }
                if !changes.insertions.isEmpty {
                    uiView.insertRows(at: changes.insertions, with: .top)
                }
                context.coordinator.notes = newNotes
            }
        } else {
            context.coordinator.notes = newNotes
            uiView.reloadData()
        }
    }


    private func calculateChanges(from oldNotes: [Note], to newNotes: [Note]) -> (deletions: [IndexPath], insertions: [IndexPath]) {
        var deletions: [IndexPath] = []
        var insertions: [IndexPath] = []

        let oldIDs = Set(oldNotes.map { $0.id })
        let newIDs = Set(newNotes.map { $0.id })

        for (index, note) in oldNotes.enumerated() {
            if !newIDs.contains(note.id) {
                deletions.append(IndexPath(row: index, section: 0))
            }
        }

        for (index, note) in newNotes.enumerated() {
            if !oldIDs.contains(note.id) {
                insertions.append(IndexPath(row: index, section: 0))
            }
        }

        return (deletions, insertions)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(notes: notes, onNoteTap: onNoteTap, onNoteDelete: onNoteDelete)
    }
    
    class Coordinator: NSObject, UITableViewDelegate, UITableViewDataSource {
        var notes: [Note]
        var onNoteTap: (Note) -> Void
        var onNoteDelete: (Note) -> Void
        var scrollIndicator: ScrollIndicator?

        init(notes: [Note], onNoteTap: @escaping (Note) -> Void, onNoteDelete: @escaping (Note) -> Void) {
            self.notes = notes
            self.onNoteTap = onNoteTap
            self.onNoteDelete = onNoteDelete
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return notes.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) as! NoteCell
            let note = notes[indexPath.row]
            cell.configure(with: note, onDelete: {
                self.onNoteDelete(note)
            })
            cell.onTap = {
                self.onNoteTap(note)
            }
            return cell
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 90
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: false)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollIndicator?.updatePosition()
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                scrollIndicator?.scheduleHide()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            scrollIndicator?.hideAfterDeceleration()
        }
    }
}

class NoteCell: UITableViewCell {
    private var currentOffset: CGFloat = 0
    private var finalOffset: CGFloat = 0
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private let deleteThreshold: CGFloat = 70
    private let deleteButtonWidth: CGFloat = 100
    private let separatorWidthRatio: CGFloat = 0.9
    
    private let deleteContainerView = UIView()
    private let deleteButton = UIButton(type: .system)
    private var deleteContainerWidthConstraint: NSLayoutConstraint!
    
    private let cellContentView = UIView()
    private let dateStackView = UIStackView()
    private let dayLabel = UILabel()
    private let monthLabel = UILabel()
    private let contentLabel = UILabel()
    private let separatorView = UIView()
    
    var onDelete: (() -> Void)?
    var onTap: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        deleteContainerView.backgroundColor = .deleteBackground
        deleteContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteContainerView)
        
        let trashIcon = UIImage(systemName: "trash")
        deleteButton.setImage(trashIcon, for: .normal)
        deleteButton.tintColor = .white
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isUserInteractionEnabled = false
        deleteContainerView.addSubview(deleteButton)

        let deleteContainerTap = UITapGestureRecognizer(target: self, action: #selector(deleteButtonTapped))
        deleteContainerView.addGestureRecognizer(deleteContainerTap)

        cellContentView.backgroundColor = .appBackground
        cellContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cellContentView)
        
        dayLabel.font = .iosevka(size: 20, weight: .bold)
        dayLabel.textColor = .label
        dayLabel.textAlignment = .center

        monthLabel.font = .iosevka(size: 12)
        monthLabel.textColor = .systemGray
        monthLabel.textAlignment = .center

        dateStackView.axis = .vertical
        dateStackView.spacing = 2
        dateStackView.alignment = .center
        dateStackView.addArrangedSubview(dayLabel)
        dateStackView.addArrangedSubview(monthLabel)
        dateStackView.translatesAutoresizingMaskIntoConstraints = false

        contentLabel.font = .iosevka(size: 16)
        contentLabel.textColor = .label
        contentLabel.numberOfLines = 1
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        separatorView.backgroundColor = .systemGray.withAlphaComponent(0.3)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        cellContentView.addSubview(dateStackView)
        cellContentView.addSubview(contentLabel)
        cellContentView.addSubview(separatorView)
        
        deleteContainerWidthConstraint = deleteContainerView.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            deleteContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            deleteContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deleteContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            deleteContainerWidthConstraint,
            
            deleteButton.centerYAnchor.constraint(equalTo: deleteContainerView.centerYAnchor),
            deleteButton.centerXAnchor.constraint(equalTo: deleteContainerView.centerXAnchor),
            
            cellContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            dateStackView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: 24),
            dateStackView.centerYAnchor.constraint(equalTo: cellContentView.centerYAnchor),
            dateStackView.widthAnchor.constraint(equalToConstant: 50),
            
            contentLabel.leadingAnchor.constraint(equalTo: dateStackView.trailingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -24),
            contentLabel.centerYAnchor.constraint(equalTo: cellContentView.centerYAnchor),
            
            separatorView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: cellContentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        cellContentView.addGestureRecognizer(tapGesture)
    }
    
    private func setupGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGestureRecognizer.delegate = self
        cellContentView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: cellContentView)

        switch gesture.state {
        case .began:
            layer.removeAllAnimations()
            break

        case .changed:
            if translation.x < 0 {
                currentOffset = finalOffset + translation.x
            } else if finalOffset < 0 {
                currentOffset = min(0, finalOffset + translation.x)
            }

            updateOffsets()

        case .ended, .cancelled:
            if currentOffset < -deleteThreshold {
                animateToOffset(-deleteButtonWidth)
            } else {
                animateToOffset(0)
            }

        default:
            break
        }
    }

    private func updateOffsets() {
        cellContentView.transform = CGAffineTransform(translationX: currentOffset, y: 0)
        
        deleteContainerWidthConstraint.constant = -currentOffset
        self.layoutIfNeeded()

        let fadeProgress = min(max((-currentOffset - deleteThreshold) / (bounds.width - deleteThreshold), 0), 1)
        deleteContainerView.backgroundColor = UIColor.deleteBackground.withAlphaComponent(1.0 - fadeProgress * 0.8)

        let buttonOpacity = min(-currentOffset / deleteButtonWidth, 1.0)
        deleteButton.alpha = buttonOpacity
    }
    
    private func animateToOffset(_ offset: CGFloat) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8 ,
                       initialSpringVelocity: 1.0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.currentOffset = offset
            self.finalOffset = offset
            self.updateOffsets()
        }
    }

    @objc private func deleteButtonTapped() {
        animateToOffset(-bounds.width)
        onDelete?()
    }
    
    func configure(with note: Note, onDelete: @escaping () -> Void) {
        self.onDelete = onDelete
        
        let firstBulletPoint = note.content.components(separatedBy: "\n").first ?? "Empty thought"
        contentLabel.text = firstBulletPoint
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayLabel.text = dayFormatter.string(from: note.date)
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        monthLabel.text = monthFormatter.string(from: note.date)
        
        currentOffset = 0
        finalOffset = 0
        updateOffsets()
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: cellContentView)
        let isHorizontal = abs(velocity.x) > abs(velocity.y)
        return isHorizontal
    }
}
