package io.github.felixrodrigo19.reserva.service.adapters.outbound.mapper;

import io.github.felixrodrigo19.reserva.service.adapters.outbound.entity.EventEntity;
import io.github.felixrodrigo19.reserva.service.domain.event.Event;
import org.springframework.stereotype.Component;

@Component
public class EventMapper {
    public static Event toDomain(EventEntity entity) {
        return new Event(entity.getId(), entity.getName(), entity.getDescription(), entity.getVenue(), entity.getCreatedAt());
    }
}
