package io.github.felixrodrigo19.reserva.service.application.usecase;

import io.github.felixrodrigo19.reserva.service.domain.event.Event;
import io.github.felixrodrigo19.reserva.service.domain.event.IEventRepository;
import io.github.felixrodrigo19.reserva.service.domain.shared.PageResult;
import io.github.felixrodrigo19.reserva.service.dto.EventFilter;


public class SearchEvents {
    private final IEventRepository repository;

    public SearchEvents(IEventRepository repository) {
        this.repository = repository;
    }

    public PageResult<Event> execute(EventFilter filter) {
        return repository.findByFilter(filter);
    }
}
