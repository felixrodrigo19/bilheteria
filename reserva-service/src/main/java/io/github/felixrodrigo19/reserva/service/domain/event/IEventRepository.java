package io.github.felixrodrigo19.reserva.service.domain.event;

import io.github.felixrodrigo19.reserva.service.domain.shared.PageResult;
import io.github.felixrodrigo19.reserva.service.dto.EventFilter;

import java.util.List;

public interface IEventRepository {
    PageResult<Event> findByFilter(EventFilter filter);
}
