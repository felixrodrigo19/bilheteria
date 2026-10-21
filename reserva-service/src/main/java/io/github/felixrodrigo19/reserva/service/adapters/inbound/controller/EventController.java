package io.github.felixrodrigo19.reserva.service.adapters.inbound.controller;

import io.github.felixrodrigo19.reserva.service.application.usecase.SearchEvents;
import io.github.felixrodrigo19.reserva.service.domain.shared.PageQuery;
import io.github.felixrodrigo19.reserva.service.dto.EventDto;
import io.github.felixrodrigo19.reserva.service.dto.EventFilter;
import io.github.felixrodrigo19.reserva.service.dto.PageResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/{version}/events")
public class EventController {
    private final SearchEvents searchEvents;

    public EventController(SearchEvents searchEvents) {
        this.searchEvents = searchEvents;
    }

    @GetMapping(version = "v1")
    public PageResponse<EventDto> getEvents(@RequestParam(defaultValue = "1") int page,
                                            @RequestParam(defaultValue = "10") int size,
                                            @RequestParam(required = false) String sort,
                                            @RequestParam(required = false, defaultValue = "true") boolean asc,
                                            @RequestParam(required = false) String venue,
                                            @RequestParam(required = false) LocalDateTime date,
                                            @RequestParam(required = false) String name,
                                            @RequestParam(required = false) String description) {
        EventFilter filter = new EventFilter(
                venue,
                date,
                name,
                description,
                new PageQuery(page, size, sort, asc)
        );

        return PageResponse.from(searchEvents.execute(filter), EventDto::from);
    }
}
