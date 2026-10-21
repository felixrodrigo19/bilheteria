package io.github.felixrodrigo19.reserva.service.dto;

import io.github.felixrodrigo19.reserva.service.domain.event.Event;

import java.time.LocalDateTime;
import java.util.UUID;

public record EventDto(UUID id, String name, String description, String venue, LocalDateTime createdAt) {
    public static EventDto from(Event event) {
        return new EventDto(event.getId(), event.getName(), event.getDescription(), event.getVenue(), event.getCreatedAt());
    }
}
