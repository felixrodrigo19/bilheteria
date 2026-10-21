package io.github.felixrodrigo19.reserva.service.domain.shared;

import java.util.List;
import java.util.function.Function;

public record PageResult<T>(List<T> items, int page, int size, long totalElements) {
    public int totalPages() {
        return (int) Math.ceil((double) totalElements / (double) size);
    }

    public <R> PageResult<R> map(Function<T, R> fn) {
        return new PageResult<>(items.stream().map(fn).toList(), page, size, totalElements);
    }
}
