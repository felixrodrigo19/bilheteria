package io.github.felixrodrigo19.reserva.service.domain.event;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

public class Event {
    private final UUID id;
    private final String name;
    private final String description;
    private final String venue;
    private final LocalDateTime createdAt;

    public Event(UUID id, String name, String description, String venue, LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.venue = venue;
        this.createdAt = createdAt;
    }

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public String getVenue() {
        return venue;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    @Override
    public boolean equals(Object object) {
        if (object == null || getClass() != object.getClass()) return false;
        Event event = (Event) object;
        return Objects.equals(id, event.id) && Objects.equals(name, event.name) && Objects.equals(description, event.description) && Objects.equals(venue, event.venue) && Objects.equals(createdAt, event.createdAt);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, description, venue, createdAt);
    }

    @Override
    public String toString() {
        return "Event{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", description='" + description + '\'' +
                ", venue='" + venue + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
}
