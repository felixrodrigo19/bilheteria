package io.github.felixrodrigo19.reserva.service.adapters.outbound.persistence;

import io.github.felixrodrigo19.reserva.service.adapters.outbound.entity.EventEntity;
import io.github.felixrodrigo19.reserva.service.adapters.outbound.mapper.EventMapper;
import io.github.felixrodrigo19.reserva.service.adapters.outbound.repository.EventRepository;
import io.github.felixrodrigo19.reserva.service.domain.event.Event;
import io.github.felixrodrigo19.reserva.service.domain.event.IEventRepository;
import io.github.felixrodrigo19.reserva.service.domain.shared.PageQuery;
import io.github.felixrodrigo19.reserva.service.domain.shared.PageResult;
import io.github.felixrodrigo19.reserva.service.dto.EventFilter;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;

@Component
public class EventRepositoryJPA implements IEventRepository {

    private static final Map<String, String> SORTABLE_FIELDS = Map.of(
            "name", "name",
            "venue", "venue",
            "createdAt", "createdAt"
    );
    private static final Sort DEFAULT_SORT = Sort.by("createdAt").descending();
    private static final Sort TIE_BREAKER = Sort.by("id").ascending();

    private final EventRepository repository;
    private final EventMapper mapper;

    public EventRepositoryJPA(EventRepository repository, EventMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public PageResult<Event> findByFilter(EventFilter filter) {
        Page<EventEntity> result = repository.findByFilter(filter.venue(), filter.date(), filter.name(), filter.description(), toPageable(filter.pageQuery()));
        return new PageResult<>(result.getContent().stream().map(EventMapper::toDomain).toList(), result.getNumber() + 1, result.getSize(), result.getTotalElements());
    }

    private Pageable toPageable(PageQuery query) {
        Sort sort = Optional.ofNullable(query.sortBy())
                .map(SORTABLE_FIELDS::get)
                .map(field -> query.ascending() ? Sort.by(field).ascending() : Sort.by(field).descending())
                .orElse(DEFAULT_SORT)
                .and(TIE_BREAKER);
        return PageRequest.of(query.page() - 1, query.size(), sort);
    }
}
