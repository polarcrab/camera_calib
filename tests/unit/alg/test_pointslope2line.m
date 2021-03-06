function test_pointslope2line
    p1 = [20 35];
    p2 = [40 52];

    m = (p2(2)-p1(2))/(p2(1)-p1(1));

    l = alg.pointslope2line(p1, m);

    %{
    % Plot example
    f = figure;
    array = zeros(62, 57);
    imshow(array, []);
    hold on;
    e1 = ezplot(@(x, y) l(1).*x + l(2).*y + l(3), [1 size(array, 2) 1 size(array, 1)]); %#ok<EZPLT>
    set(e1, 'color', 'g');
    plot(p1(1), p1(2), 'rs');
    plot(p2(1), p2(2), 'rs');
    pause(1);
    close(f);
    %}

    % Assert
    assert(all(all(abs(l - [0.850000000000000  -1.000000000000000  18.000000000000000]') < 1e-4)));
end
