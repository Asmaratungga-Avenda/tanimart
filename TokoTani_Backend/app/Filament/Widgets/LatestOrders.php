<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class LatestOrders extends TableWidget
{
    protected static ?int $sort = 2;

    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Pesanan Terbaru';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => Order::query()->latest()->limit(5))
            ->columns([
                TextColumn::make('id')->label('No. Pesanan')->formatStateUsing(fn ($state) => "#{$state}"),
                TextColumn::make('nama_penerima')
                    ->label('Penerima'),
                TextColumn::make('total_harga')
                    ->label('Total Belanja')
                    ->money('IDR', locale: 'id'),
                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'menunggu_pembayaran' => 'Menunggu Pembayaran',
                        'menunggu_konfirmasi' => 'Menunggu Konfirmasi',
                        'dibayar' => 'Dibayar',
                        'diproses' => 'Diproses',
                        'dikirim' => 'Dikirim',
                        'tiba' => 'Tiba',
                        'selesai' => 'Selesai',
                        'dibatalkan' => 'Dibatalkan',
                        default => ucfirst((string) $state),
                    })
                    ->color(fn (?string $state): string => match ($state) {
                        'menunggu_pembayaran', 'menunggu_konfirmasi' => 'warning',
                        'dibayar', 'diproses' => 'info',
                        'dikirim' => 'primary',
                        'tiba' => 'warning',
                        'selesai' => 'success',
                        'dibatalkan' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('created_at')
                    ->label('Waktu Pesan')
                    ->dateTime('d/m/Y H:i'),
            ])
            ->recordActions([
                Action::make('detail')
                    ->label('Detail')
                    ->url(fn (Order $record): string => OrderResource::getUrl('view', ['record' => $record])),
            ]);
    }
}
